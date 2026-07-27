import '../models/attendance_record.dart';
import '../models/gram_sabha_meeting.dart';
import '../models/quorum_status.dart';
import '../models/village_member.dart';

/// Quorum and inclusion validation service
///
/// Implements FRA Rule 4 quorum validation:
///   Q_valid = 1 if (A/R ≥ 0.5) AND (W/A ≥ 1/3), else 0
///
/// Enhanced quorum for consent resolutions (2009 MoEFCC Circular):
///   Standard quorum + adequate ST representation + PVTG presence
///
/// Source: VanMitra-AI Technical Report, Section 8.2
class QuorumService {
  /// Calculate quorum status from attendance records
  ///
  /// [attendanceRecords] — all verified attendance for the meeting
  /// [allMembers] — full registered adult member list of the village
  /// [meetingType] — determines whether standard or enhanced quorum applies
  QuorumStatus calculateQuorum({
    required List<AttendanceRecord> attendanceRecords,
    required List<VillageMember> allMembers,
    required MeetingType meetingType,
  }) {
    final totalRegistered = allMembers.where((m) => m.isActive).length;
    final totalPresent = attendanceRecords.length;

    // Count by category
    int womenPresent = 0;
    int menPresent = 0;
    int stPresent = 0;
    int pvtgPresent = 0;
    int otfdPresent = 0;

    for (final record in attendanceRecords) {
      if (record.isWoman) {
        womenPresent++;
      } else {
        menPresent++;
      }

      if (record.isST) {
        stPresent++;
      } else if (record.isPVTG) {
        pvtgPresent++;
      } else if (record.category == 'otfd') {
        otfdPresent++;
      }
    }

    return QuorumStatus(
      totalRegistered: totalRegistered,
      totalPresent: totalPresent,
      womenPresent: womenPresent,
      menPresent: menPresent,
      stPresent: stPresent,
      pvtgPresent: pvtgPresent,
      otfdPresent: otfdPresent,
      meetingType: meetingType,
    );
  }

  /// Generate a detailed inclusion report
  ///
  /// Shows breakdown of attendance by gender, ST, PVTG, OTFD
  /// with threshold comparisons and specific violation details
  InclusionReport generateInclusionReport({
    required QuorumStatus quorum,
    required List<VillageMember> allMembers,
  }) {
    // Count registered members by category
    final registeredWomen = allMembers.where((m) => m.isWoman && m.isActive).length;
    final registeredST = allMembers.where((m) => m.isST && m.isActive).length;
    final registeredPVTG = allMembers.where((m) => m.isPVTG && m.isActive).length;

    return InclusionReport(
      quorum: quorum,
      registeredWomen: registeredWomen,
      registeredST: registeredST,
      registeredPVTG: registeredPVTG,
      womenTurnoutPercentage: registeredWomen > 0
          ? (quorum.womenPresent / registeredWomen) * 100
          : 0.0,
      stTurnoutPercentage: registeredST > 0
          ? (quorum.stPresent / registeredST) * 100
          : 0.0,
      pvtgTurnoutPercentage: registeredPVTG > 0
          ? (quorum.pvtgPresent / registeredPVTG) * 100
          : 0.0,
    );
  }

  /// Check if a specific resolution type can be recorded given current quorum
  ///
  /// For consent resolutions: enhanced quorum must be met
  /// For other types: standard quorum suffices
  ResolutionEligibility checkResolutionEligibility({
    required QuorumStatus quorum,
    required String resolutionType,
  }) {
    final isConsentResolution = resolutionType == 'consentForDiversion';

    if (isConsentResolution) {
      return ResolutionEligibility(
        canRecord: quorum.isEnhancedQuorumValid,
        requiresEnhancedQuorum: true,
        violations: quorum.violations,
        message: quorum.isEnhancedQuorumValid
            ? 'Enhanced quorum met — consent resolution can be recorded'
            : 'Enhanced quorum NOT met — cannot record consent resolution. '
                'Violations: ${quorum.violations.join("; ")}',
      );
    }

    return ResolutionEligibility(
      canRecord: quorum.isStandardQuorumValid,
      requiresEnhancedQuorum: false,
      violations: quorum.violations,
      message: quorum.isStandardQuorumValid
          ? 'Quorum met — resolution can be recorded'
          : 'Quorum NOT met — resolution will be flagged as non-compliant',
    );
  }
}

/// Detailed inclusion breakdown
class InclusionReport {
  final QuorumStatus quorum;
  final int registeredWomen;
  final int registeredST;
  final int registeredPVTG;
  final double womenTurnoutPercentage;
  final double stTurnoutPercentage;
  final double pvtgTurnoutPercentage;

  const InclusionReport({
    required this.quorum,
    required this.registeredWomen,
    required this.registeredST,
    required this.registeredPVTG,
    required this.womenTurnoutPercentage,
    required this.stTurnoutPercentage,
    required this.pvtgTurnoutPercentage,
  });
}

/// Whether a resolution can be recorded given current quorum
class ResolutionEligibility {
  final bool canRecord;
  final bool requiresEnhancedQuorum;
  final List<String> violations;
  final String message;

  const ResolutionEligibility({
    required this.canRecord,
    required this.requiresEnhancedQuorum,
    required this.violations,
    required this.message,
  });
}
