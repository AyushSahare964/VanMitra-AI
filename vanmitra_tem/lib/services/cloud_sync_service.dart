import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_database.dart';
import '../models/sync_item.dart';
import 'firestore_service.dart';

/// Processes the local Hive sync queue and writes to Firestore
/// in the correct referential priority order.
class CloudSyncService {
  final FirestoreService _fs = FirestoreService();
  final Box<Map> _queue = Hive.box<Map>(HiveDatabase.syncQueueBox);

  /// Synchronize all pending items in priority order.
  Future<void> syncPendingItems() async {
    final pendingRaw = _queue.values
        .where((m) => m['status'] == SyncStatus.pending.name)
        .toList();

    if (pendingRaw.isEmpty) return;

    // Convert and sort by referential priority
    final pending = pendingRaw
        .map((m) => SyncItem.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => _priority(a.entityType).compareTo(_priority(b.entityType)));

    for (final item in pending) {
      try {
        await _syncItem(item);
        await _markDone(item.id);
        // FIX (Problem 7): inject userId and villageId into every log entry.
        // The old logSync only spread item.toJson() which had no userId/villageId.
        // The Firestore rule requires request.resource.data.userId == request.auth.uid,
        // so every audit log write was silently denied without userId.
        await _fs.logSync({
          ...item.toJson(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'villageId': item.payload['villageId'] ?? '',
          'status': 'success',
          'syncedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        await _incrementRetry(item.id, e.toString());
      }
    }
  }

  /// Maps the sync action to the appropriate Firestore write.
  Future<void> _syncItem(SyncItem item) async {
    switch (item.action) {
      case SyncAction.createClaim:
      case SyncAction.updateClaim:
      case SyncAction.submitClaim:
        await _fs.upsertClaim(item.payload);
        break;
      case SyncAction.createMeeting:
      case SyncAction.updateMeeting:
        await _fs.upsertMeeting(item.payload);
        break;
      case SyncAction.markAttendance:
        await _fs.createAttendance(item.payload);
        break;
      case SyncAction.createResolution:
        await _fs.createResolution(item.payload);
        break;
      case SyncAction.reportAlert:
        await _fs.createBoundaryAlert(item.payload);
        break;
      // Module C: publish MoM record — gets canonical server timestamp back
      case SyncAction.publishMomRecord:
        final firestoreTs = await _fs.publishMomRecord(item.payload);
        // Reconcile: update local Hive ledger entry with canonical hash
        final ledgerBox = Hive.box<Map>(HiveDatabase.localLedgerBox);
        final recordId = item.entityId;
        final existing = ledgerBox.get(recordId);
        if (existing != null) {
          final updated = Map<String, dynamic>.from(existing);
          updated['firestoreTimestamp'] = firestoreTs;
          updated['synced'] = true;
          await ledgerBox.put(recordId, updated);
        }
        break;
      // Module C: sync face embedding (never raw photo — embedding only)
      case SyncAction.syncFaceEnrollment:
        await _fs.syncFaceEnrollment(item.entityId, item.payload);
        break;
      case SyncAction.enrollFace:
        // Legacy enrollFace — delegated to syncFaceEnrollment
        await _fs.syncFaceEnrollment(item.entityId, item.payload);
        break;
      default:
        break;
    }
  }

  /// Define sync order to maintain referential integrity.
  int _priority(String entityType) {
    const order = [
      'village_member',
      'meeting',
      'attendance',
      'resolution',
      'claim',
      'boundary_alert',
      'notice'
    ];
    final index = order.indexOf(entityType);
    return index == -1 ? 99 : index;
  }

  Future<void> _markDone(String syncId) async {
    final key = _queue.keys.firstWhere((k) {
      final item = _queue.get(k);
      return item != null && item['id'] == syncId;
    }, orElse: () => null);

    if (key != null) {
      final item = Map<String, dynamic>.from(_queue.get(key)!);
      item['status'] = SyncStatus.completed.name;
      await _queue.put(key, item);
    }
  }

  Future<void> _incrementRetry(String syncId, String error) async {
    final key = _queue.keys.firstWhere((k) {
      final item = _queue.get(k);
      return item != null && item['id'] == syncId;
    }, orElse: () => null);

    if (key != null) {
      final item = Map<String, dynamic>.from(_queue.get(key)!);
      final attemptCount = (item['attemptCount'] as int? ?? 0) + 1;
      
      item['attemptCount'] = attemptCount;
      item['errorMessage'] = error;
      item['lastAttemptAt'] = DateTime.now().toIso8601String();

      // If failed too many times, mark as failed instead of pending
      if (attemptCount >= 5) {
        item['status'] = SyncStatus.failed.name;
      }
      
      await _queue.put(key, item);
    }
  }
}
