import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mom_record.dart';

/// Module C — Local Ledger Service
///
/// Provisional client-side SHA-256 hash chain.
///
/// Formula: Hₙ = SHA256(Hₙ₋₁ ∥ canonical_json(Dₙ) ∥ tₙ_device)
///
/// Key design points:
/// - The chain is PROVISIONAL — it lets the Secretary see an integrity badge
///   immediately, even while fully offline.
/// - Once synced, Firestore's server timestamp replaces tₙ and the canonical
///   hash is overwritten with the server-computed value.
/// - [verifyChain()] re-computes every hash from scratch and returns false if
///   any record has been tampered with.
///
/// Stored in Hive box [_boxName] as a list of Map entries.
class LocalLedgerService {
  static const String _boxName = 'localLedgerBox';

  final String villageId;
  late final String _genesisHash;

  LocalLedgerService(this.villageId) {
    // Genesis hash: SHA256("GENESIS:{villageId}") — deterministic root of the chain
    _genesisHash =
        sha256.convert(utf8.encode('GENESIS:$villageId')).toString();
  }

  // ── Read helpers ──────────────────────────────────────────────────────────

  Box<Map> get _box => Hive.box<Map>(_boxName);

  List<Map<String, dynamic>> get _chain =>
      _box.values
          .map((v) => Map<String, dynamic>.from(v))
          .where((m) => m['villageId'] == villageId)
          .toList()
        ..sort((a, b) =>
            (a['chainIndex'] as int).compareTo(b['chainIndex'] as int));

  String get _previousHash =>
      _chain.isEmpty ? _genesisHash : _chain.last['hash'] as String;

  int get _nextIndex => _chain.isEmpty ? 1 : (_chain.last['chainIndex'] as int) + 1;

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Add a [MomRecord] to the local chain and return the provisional hash.
  ///
  /// Called by [MomAssemblyService] immediately after assembly, even offline.
  Future<String> addRecord(MomRecord record) async {
    final timestamp = record.timestampUtc;
    final canonicalJson = jsonEncode(_sortedMap(record.toCanonicalJson()));
    final combined = '${_previousHash}|$canonicalJson|$timestamp';
    final newHash = sha256.convert(utf8.encode(combined)).toString();

    final entry = <String, dynamic>{
      'villageId': villageId,
      'chainIndex': _nextIndex,
      'recordId': record.id,
      'record': record.toCanonicalJson(),
      'timestamp': timestamp,
      'hash': newHash,
      'previousHash': _previousHash,
      'synced': false,
    };

    await _box.put(record.id, entry);
    return newHash;
  }

  /// Mark a chain entry as synced and store the canonical server hash.
  Future<void> reconcileWithServer({
    required String recordId,
    required String canonicalHash,
    required String firestoreTimestamp,
  }) async {
    final existing = _box.get(recordId);
    if (existing == null) return;
    final updated = Map<String, dynamic>.from(existing);
    updated['canonicalHash'] = canonicalHash;
    updated['firestoreTimestamp'] = firestoreTimestamp;
    updated['synced'] = true;
    await _box.put(recordId, updated);
  }

  // ── Verification ───────────────────────────────────────────────────────────

  /// Re-compute every hash in the chain from scratch.
  ///
  /// Returns false (and sets [brokenAtIndex]) if any record has been tampered with.
  /// The result drives the [IntegrityBadge] on [MomViewerScreen].
  ChainVerification verifyChain() {
    final chain = _chain;
    if (chain.isEmpty) {
      return const ChainVerification(isValid: true, totalBlocks: 0);
    }

    var prevHash = _genesisHash;
    for (int i = 0; i < chain.length; i++) {
      final entry = chain[i];
      final recordJson = jsonEncode(_sortedMap(
        Map<String, dynamic>.from(entry['record'] as Map),
      ));
      final timestamp = entry['timestamp'] as String;
      final combined = '$prevHash|$recordJson|$timestamp';
      final recomputed = sha256.convert(utf8.encode(combined)).toString();

      if (recomputed != entry['hash']) {
        return ChainVerification(
          isValid: false,
          totalBlocks: chain.length,
          brokenAtIndex: i,
          message: 'Block #$i hash mismatch — data may have been altered',
        );
      }
      prevHash = entry['hash'] as String;
    }

    return ChainVerification(
      isValid: true,
      totalBlocks: chain.length,
      message: 'Chain integrity verified — all ${chain.length} blocks authentic',
    );
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> unsyncedEntries() =>
      _chain.where((e) => e['synced'] == false).toList();

  // ── Private ────────────────────────────────────────────────────────────────

  /// Deterministic key ordering — MUST match the server's JSON serialization
  Map<String, dynamic> _sortedMap(Map<String, dynamic> m) =>
      Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

/// Result of [LocalLedgerService.verifyChain()]
class ChainVerification {
  final bool isValid;
  final int totalBlocks;
  final int? brokenAtIndex;
  final String? message;

  const ChainVerification({
    required this.isValid,
    this.totalBlocks = 0,
    this.brokenAtIndex,
    this.message,
  });
}
