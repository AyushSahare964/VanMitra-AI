import 'package:uuid/uuid.dart';
import '../models/mom_record.dart';
import '../models/resolution_model.dart';
import 'quorum_engine.dart';
import 'local_ledger_service.dart';

/// Module C — MoM Assembly Service
///
/// Assembles a [MomRecord] (Dₙ) from all the pieces collected during a meeting:
/// - Attendance entries + quorum result
/// - Reviewed resolution (trilingual)
/// - GPS geotag + device timestamp
/// - Group photo path (if captured)
///
/// Also sets [MomRecord.localHash] by calling [LocalLedgerService.addRecord()]
/// so the integrity badge is visible immediately, even offline.
class MomAssemblyService {
  final LocalLedgerService _ledger;
  final _uuid = const Uuid();

  MomAssemblyService({required LocalLedgerService ledger}) : _ledger = ledger;

  /// Assemble a [MomRecord] and add it to the local provisional ledger.
  ///
  /// [resolution.isUserReviewed] must be true — this method asserts it.
  /// The Secretary's confirmation on [ResolutionRecordingScreen] sets this flag.
  Future<MomRecord> assembleMom({
    required String meetingId,
    required String villageId,
    required String geotag,
    required List<AttendanceEntry> attendees,
    required int registeredCount,
    required ResolutionModel resolution,
    String? groupPhotoLocalPath,
  }) async {
    assert(
      resolution.isUserReviewed,
      'assembleMom called with unreviewed resolution — '
      'ResolutionRecordingScreen must set isUserReviewed=true before proceeding',
    );

    final quorum = QuorumEngine.evaluate(attendees, registeredCount);
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    // Build the record WITHOUT a hash first (addRecord will set it)
    final partial = MomRecord(
      id: id,
      meetingId: meetingId,
      villageId: villageId,
      meetingDate: now.toIso8601String(),
      geotag: geotag,
      decisionTextEn: resolution.textEn,
      decisionTextHi: resolution.textHi,
      decisionTextMr: resolution.textMr,
      sourceLanguage: resolution.sourceLanguage,
      attendeeCount: quorum.a,
      registeredCount: quorum.r,
      womenCount: quorum.w,
      quorumValid: quorum.qValid,
      quorumExplanation: quorum.explain(),
      faceMatchedCount: quorum.faceMatchedCount,
      manualAddedCount: quorum.manualAddedCount,
      localHash: '', // filled below
      timestampUtc: now.toIso8601String(),
      groupPhotoLocalPath: groupPhotoLocalPath,
      isSynced: false,
    );

    // Add to the provisional chain — anchors the record
    await _ledger.addRecord(partial);

    return partial.copyWith();
    // Note: MomRecord.localHash is set by the ledger box; retrieve via LocalLedgerService
    // if needed. The record returned here is the canonical assembled payload.
    // For the full record with hash, use assembleMomWithHash() instead.
  }

  /// Convenience: assemble and return the full record including the local hash.
  Future<MomRecord> assembleMomWithHash({
    required String meetingId,
    required String villageId,
    required String geotag,
    required List<AttendanceEntry> attendees,
    required int registeredCount,
    required ResolutionModel resolution,
    String? groupPhotoLocalPath,
  }) async {
    assert(resolution.isUserReviewed, 'Resolution must be reviewed before assembly');

    final quorum = QuorumEngine.evaluate(attendees, registeredCount);
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    // Placeholder record to compute canonical JSON for hashing
    final placeholder = MomRecord(
      id: id,
      meetingId: meetingId,
      villageId: villageId,
      meetingDate: now.toIso8601String(),
      geotag: geotag,
      decisionTextEn: resolution.textEn,
      decisionTextHi: resolution.textHi,
      decisionTextMr: resolution.textMr,
      sourceLanguage: resolution.sourceLanguage,
      attendeeCount: quorum.a,
      registeredCount: quorum.r,
      womenCount: quorum.w,
      quorumValid: quorum.qValid,
      quorumExplanation: quorum.explain(),
      faceMatchedCount: quorum.faceMatchedCount,
      manualAddedCount: quorum.manualAddedCount,
      localHash: 'PENDING',
      timestampUtc: now.toIso8601String(),
      groupPhotoLocalPath: groupPhotoLocalPath,
      isSynced: false,
    );

    final localHash = await _ledger.addRecord(placeholder);

    return MomRecord(
      id: id,
      meetingId: meetingId,
      villageId: villageId,
      meetingDate: now.toIso8601String(),
      geotag: geotag,
      decisionTextEn: resolution.textEn,
      decisionTextHi: resolution.textHi,
      decisionTextMr: resolution.textMr,
      sourceLanguage: resolution.sourceLanguage,
      attendeeCount: quorum.a,
      registeredCount: quorum.r,
      womenCount: quorum.w,
      quorumValid: quorum.qValid,
      quorumExplanation: quorum.explain(),
      faceMatchedCount: quorum.faceMatchedCount,
      manualAddedCount: quorum.manualAddedCount,
      localHash: localHash,
      timestampUtc: now.toIso8601String(),
      groupPhotoLocalPath: groupPhotoLocalPath,
      isSynced: false,
    );
  }
}
