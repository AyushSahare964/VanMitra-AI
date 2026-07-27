import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_database.dart';
import '../models/claim.dart';
import '../models/sync_item.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

/// Claims state
class ClaimsState {
  final List<Claim> claims;
  final bool isLoading;

  const ClaimsState({this.claims = const [], this.isLoading = false});

  ClaimsState copyWith({List<Claim>? claims, bool? isLoading}) {
    return ClaimsState(
      claims: claims ?? this.claims,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Claim> get approvedClaims =>
      claims.where((c) => c.status == ClaimStatus.approved).toList();
  List<Claim> get pendingClaims =>
      claims.where((c) => c.status != ClaimStatus.approved && c.status != ClaimStatus.rejected).toList();
  int get totalApprovedArea =>
      approvedClaims.fold<int>(0, (s, c) => s + (c.areaSqMeters?.toInt() ?? 0));
}

class ClaimsNotifier extends StateNotifier<ClaimsState> {
  ClaimsNotifier() : super(const ClaimsState());

  /// FIX (Problem 9): Removed auto-seeding of OzharClaimsSeed.
  /// Seed claims had fake claimantUserIds — new users saw demo data mixed with
  /// their own. New installs now start with an empty claims list and display
  /// a proper CTA to file the first claim.
  Future<void> loadClaims(String villageId) async {
    state = state.copyWith(isLoading: true);
    final box = Hive.box<Map>(HiveDatabase.claimsBox);

    // FIX: no longer seeds OzharClaimsSeed on empty box.
    // Seed data is for dev/demo only — use the Firestore stream in production.

    final claims = box.values
        .map((v) => Claim.fromJson(Map<String, dynamic>.from(v)))
        .where((c) => c.villageId == villageId)
        .toList();

    state = ClaimsState(claims: claims);
  }

  Future<void> addClaim(Claim claim) async {
    final box = Hive.box<Map>(HiveDatabase.claimsBox);
    await box.put(claim.id, claim.toJson());
    state = state.copyWith(claims: [...state.claims, claim]);

    // Enqueue sync item
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.createClaim,
      status: SyncStatus.pending,
      entityId: claim.id,
      entityType: 'claim',
      payload: claim.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());
  }

  Future<void> updateClaim(Claim claim) async {
    final box = Hive.box<Map>(HiveDatabase.claimsBox);
    await box.put(claim.id, claim.toJson());
    final updated = state.claims.map((c) => c.id == claim.id ? claim : c).toList();
    state = state.copyWith(claims: updated);

    // Enqueue sync item
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.updateClaim,
      status: SyncStatus.pending,
      entityId: claim.id,
      entityType: 'claim',
      payload: claim.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());
  }
}

final claimsProvider = StateNotifierProvider<ClaimsNotifier, ClaimsState>((ref) {
  return ClaimsNotifier();
});

/// Real-time stream of ALL claims for a village (admin view).
final claimsStreamProvider = StreamProvider.family<List<Claim>, String>((ref, villageId) {
  return FirestoreService().streamClaims(villageId).map((snapshot) =>
      snapshot.docs.map((d) => Claim.fromJson(d.data() as Map<String, dynamic>)).toList());
});

/// FIX: Real-time stream of claims filtered to the current user only.
/// Queries Firestore directly by claimantUserId so we don't need a villageId.
/// Falls back to an empty list on error (never shows a blank/stuck screen).
final userClaimsStreamProvider = StreamProvider<List<Claim>>((ref) {
  final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return FirestoreService()
      .streamUserClaims(uid)
      .map((snapshot) => snapshot.docs
          .map((d) => Claim.fromJson(d.data() as Map<String, dynamic>))
          .toList())
      .handleError((_) => <Claim>[]);
});
