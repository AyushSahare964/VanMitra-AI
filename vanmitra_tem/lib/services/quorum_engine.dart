import '../models/attendance_record.dart';

/// Module C — Quorum Engine (pure Dart)
///
/// Implements Requirements §3.2 exactly:
///   Q_valid = (A/R ≥ 0.5) AND (W/A ≥ 1/3)
///
/// This replaces the old QuorumService. The key difference:
/// - Works with [AttendanceEntry] (Module C) which carries captureMethod
/// - [QuorumResult.explain()] gives a human-readable violation message (§7 explainability)
/// - [QuorumEngine.fromLegacy] bridges the old [AttendanceRecord] type so nothing breaks

// ── Data types ───────────────────────────────────────────────────────────────

/// A single verified attendee at a Gram Sabha session
class AttendanceEntry {
  final String memberId;
  final String memberName;
  final bool isWoman;

  /// How this attendee was verified:
  /// 'face_match' — FaceNet embedding matched above threshold
  /// 'manual'     — Secretary manually added (always visibly tagged in UI)
  final String captureMethod;

  /// UTC timestamp of check-in
  final DateTime checkedInAt;

  const AttendanceEntry({
    required this.memberId,
    required this.memberName,
    required this.isWoman,
    required this.captureMethod,
    required this.checkedInAt,
  });
}

/// Result of a quorum calculation
class QuorumResult {
  /// Q_valid = (A/R ≥ 0.5) AND (W/A ≥ 1/3)
  final bool qValid;

  /// A — attendees, R — registered members, W — women attendees
  final int a, r, w;

  final double attendanceRatioPct; // (A/R) × 100
  final double womenRatioPct;      // (W/A) × 100
  final int faceMatchedCount;
  final int manualAddedCount;

  const QuorumResult({
    required this.qValid,
    required this.a,
    required this.r,
    required this.w,
    required this.attendanceRatioPct,
    required this.womenRatioPct,
    required this.faceMatchedCount,
    required this.manualAddedCount,
  });

  /// §7 Explainability — human-readable reason string, never a generic "failed".
  /// Used by [QuorumPanelWidget] and stored in [MomRecord.quorumExplanation].
  String explain() {
    if (qValid) {
      return 'Quorum met: ${attendanceRatioPct.toStringAsFixed(1)}% attendance, '
          '${womenRatioPct.toStringAsFixed(1)}% women.';
    }
    final parts = <String>[];
    if (attendanceRatioPct < 50) {
      parts.add(
        'Only ${attendanceRatioPct.toStringAsFixed(1)}% attended — 50% required '
        '($a of $r registered members present)',
      );
    }
    if (womenRatioPct < 33.33) {
      parts.add(
        'Only ${womenRatioPct.toStringAsFixed(1)}% women — 33% required '
        '($w of $a attendees are women)',
      );
    }
    return parts.join('; ');
  }

  /// Attendance ratio as a fraction for progress indicators (0.0–1.0, capped)
  double get attendanceRatio => (attendanceRatioPct / 100).clamp(0.0, 1.0);

  /// Women ratio as a fraction for progress indicators (0.0–1.0, capped)
  double get womenRatio => (womenRatioPct / 100).clamp(0.0, 1.0);
}

// ── Engine ───────────────────────────────────────────────────────────────────

/// Pure-Dart quorum validation — no dependencies, fully offline, unit-testable
class QuorumEngine {
  /// Evaluate quorum from a list of [AttendanceEntry] objects.
  ///
  /// [attendees]       — verified attendees for the current session
  /// [registeredCount] — total registered adult members on the village roll
  static QuorumResult evaluate(
    List<AttendanceEntry> attendees,
    int registeredCount,
  ) {
    final a = attendees.length;
    final r = registeredCount;
    final w = attendees.where((e) => e.isWoman).length;
    final faceMatched =
        attendees.where((e) => e.captureMethod == 'face_match').length;

    final attendanceRatio = r > 0 ? a / r : 0.0;
    final womenRatio = a > 0 ? w / a : 0.0;
    final qValid = attendanceRatio >= 0.5 && womenRatio >= (1 / 3);

    return QuorumResult(
      qValid: qValid,
      a: a,
      r: r,
      w: w,
      attendanceRatioPct: attendanceRatio * 100,
      womenRatioPct: womenRatio * 100,
      faceMatchedCount: faceMatched,
      manualAddedCount: a - faceMatched,
    );
  }

  /// Bridge adapter — converts the legacy [AttendanceRecord] list used by the
  /// old meeting_provider into [AttendanceEntry] objects so historical records
  /// still display correct quorum data without a migration.
  static QuorumResult fromLegacy(
    List<AttendanceRecord> records,
    int registeredCount,
  ) {
    final entries = records
        .map(
          (r) => AttendanceEntry(
            memberId: r.memberId,
            memberName: r.memberName,
            isWoman: r.isWoman,
            captureMethod:
                r.method == VerificationMethod.gpsFace ? 'face_match' : 'manual',
            checkedInAt: r.timestamp,
          ),
        )
        .toList();
    return evaluate(entries, registeredCount);
  }
}
