import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Centralized data-access layer wrapping Firestore reads and writes.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Reads (Streams) ───────────────────────────────────────────────────

  Stream<QuerySnapshot> streamClaims(String villageId) =>
      _db.collection('claims')
         .where('villageId', isEqualTo: villageId)
         .orderBy('createdAt', descending: true)
         .snapshots();

  /// Stream claims for a specific user (by UID), ordered by creation date.
  /// Used by [userClaimsStreamProvider] in MyClaimsScreen.
  Stream<QuerySnapshot> streamUserClaims(String uid) =>
      _db.collection('claims')
         .where('claimantUserId', isEqualTo: uid)
         .orderBy('createdAt', descending: true)
         .snapshots();

  Stream<QuerySnapshot> streamMeetings(String villageId) =>
      _db.collection('gram_sabha_meetings')
         .where('villageId', isEqualTo: villageId)
         .where('status', whereNotIn: ['cancelled'])
         .orderBy('scheduledDate', descending: true)
         .snapshots();

  Stream<QuerySnapshot> streamAttendance(String meetingId) =>
      _db.collection('attendance_records')
         .where('meetingId', isEqualTo: meetingId)
         .orderBy('timestamp')
         .snapshots();

  Stream<QuerySnapshot> streamResolutions(String villageId) =>
      _db.collection('resolutions')
         .where('villageId', isEqualTo: villageId)
         .orderBy('blockIndex')
         .snapshots();

  Stream<QuerySnapshot> streamNotices(String villageId) =>
      _db.collection('notices')
         .where('validUntil', isGreaterThan: Timestamp.now())
         .snapshots();

  Stream<QuerySnapshot> streamBoundaryAlerts(String villageId) =>
      _db.collection('boundary_alerts')
         .where('villageId', isEqualTo: villageId)
         .where('tier', isEqualTo: 'red')
         .snapshots();

  // ─── Writes (Idempotent) ───────────────────────────────────────────────

  Future<void> upsertClaim(Map<String, dynamic> data) =>
      _db.collection('claims').doc(data['id']).set(data, SetOptions(merge: true));

  Future<void> upsertMeeting(Map<String, dynamic> data) =>
      _db.collection('gram_sabha_meetings').doc(data['id']).set(data, SetOptions(merge: true));

  Future<void> createAttendance(Map<String, dynamic> data) =>
      // Deterministic ID (ATT_{meetingId}_{memberId}) makes this idempotent
      _db.collection('attendance_records').doc(data['id']).set(data);

  Future<void> createResolution(Map<String, dynamic> data) =>
      // Security rules block updates — set() will only succeed once
      _db.collection('resolutions').doc(data['id']).set(data);

  Future<void> createNotice(Map<String, dynamic> data) =>
      _db.collection('notices').doc(data['noticeId']).set(data);

  Future<void> createBoundaryAlert(Map<String, dynamic> data) =>
      _db.collection('boundary_alerts').doc(data['id']).set(data);
      
  Future<void> logSync(Map<String, dynamic> data) =>
      _db.collection('sync_audit_log').add(data);

  // ── Module C: MoM Records ─────────────────────────────────────────────────

  /// Publish a MoM record — append-only (Firestore security rules block updates).
  /// Returns the server timestamp string as the canonical tₙ for the hash chain.
  Future<String> publishMomRecord(Map<String, dynamic> data) async {
    final ref = _db.collection('gram_sabha_mom_records').doc(data['id'] as String);
    await ref.set({
      ...data,
      'serverTimestamp': FieldValue.serverTimestamp(),
    });
    final snap = await ref.get();
    final ts = snap.data()?['serverTimestamp'];
    if (ts is Timestamp) {
      return ts.toDate().toIso8601String();
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Stream MoM records for a village, ordered by device timestamp.
  Stream<QuerySnapshot> streamMomRecords(String villageId) =>
      _db
          .collection('gram_sabha_mom_records')
          .where('villageId', isEqualTo: villageId)
          .orderBy('timestampUtc')
          .snapshots();

  /// Verify the Firestore MoM chain for a village.
  ///
  /// Reads all records in order and recomputes SHA-256 hashes to detect tampering.
  /// Returns true if the chain is intact, false if any record has been modified.
  Future<bool> verifyMomChain(String villageId) async {
    final snapshot = await _db
        .collection('gram_sabha_mom_records')
        .where('villageId', isEqualTo: villageId)
        .orderBy('timestampUtc')
        .get();
    if (snapshot.docs.isEmpty) return true;

    final genesisHash =
        sha256.convert(utf8.encode('GENESIS:$villageId')).toString();
    String prevHash = genesisHash;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Reconstruct canonical JSON in sorted-key order
      final canonicalMap = <String, dynamic>{
        'decision_text_en': data['decisionTextEn'] ?? '',
        'decision_text_hi': data['decisionTextHi'] ?? '',
        'decision_text_mr': data['decisionTextMr'] ?? '',
        'geotag': data['geotag'] ?? '',
        'group_photo_path': data['groupPhotoLocalPath'],
        'meeting_date': data['meetingDate'] ?? '',
        'quorum': {
          'A': data['attendeeCount'] ?? 0,
          'R': data['registeredCount'] ?? 0,
          'W': data['womenCount'] ?? 0,
          'Q_valid': data['quorumValid'] ?? false,
        },
        'source_language': data['sourceLanguage'] ?? 'mr',
        'village_id': data['villageId'] ?? '',
      };
      final sortedMap = Map.fromEntries(
        canonicalMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      final timestamp = data['timestampUtc'] as String? ?? '';
      final combined = '$prevHash|${jsonEncode(sortedMap)}|$timestamp';
      final expected = sha256.convert(utf8.encode(combined)).toString();

      final storedHash = data['localHash'] as String? ?? '';
      if (expected != storedHash) return false;
      prevHash = storedHash;
    }
    return true;
  }

  // ── Module C: Face Enrollments (embedding only — no raw photos) ───────────

  /// Sync a member's face embedding to Firestore.
  /// Only the 128-dim vector is stored — raw photos are never uploaded.
  Future<void> syncFaceEnrollment(
    String memberId,
    Map<String, dynamic> data,
  ) =>
      _db
          .collection('gram_sabha_face_enrollments')
          .doc(memberId)
          .set(data, SetOptions(merge: true));

  /// Fetch all face embeddings for a village.
  /// Returns Map<memberId, List<double>> for loading into [faceEnrollmentsProvider].
  Future<Map<String, List<double>>> fetchFaceEnrollments(String villageId) async {
    final snap = await _db
        .collection('gram_sabha_face_enrollments')
        .where('villageId', isEqualTo: villageId)
        .get();
    final result = <String, List<double>>{};
    for (final doc in snap.docs) {
      final raw = doc.data()['embedding'] as List<dynamic>?;
      if (raw != null) {
        result[doc.id] = raw.map((e) => (e as num).toDouble()).toList();
      }
    }
    return result;
  }
}
