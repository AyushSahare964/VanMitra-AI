import 'package:uuid/uuid.dart';
import '../models/attendance_record.dart';
import '../models/village_member.dart';
import 'geofencing_service.dart';

/// Orchestrates the 3-layer attendance verification:
///   Layer 1: GPS Geofence Check
///   Layer 2: Face Recognition Verification
///   Layer 3: Composite Verification Record
///
/// Also supports admin manual override for members without smartphones.
class AttendanceService {
  final GeofencingService _geofencingService;
  final _uuid = const Uuid();

  AttendanceService({GeofencingService? geofencingService})
      : _geofencingService = geofencingService ?? GeofencingService();

  /// Full self-attendance flow: GPS → Face → Record
  ///
  /// Returns [AttendanceResult] with the created record or failure reason.
  Future<AttendanceResult> markSelfAttendance({
    required VillageMember member,
    required String meetingId,
    required String villageId,
    required double venueLat,
    required double venueLng,
    required double deviceLat,
    required double deviceLng,
    required double gpsAccuracy,
    required double faceMatchConfidence,
    required bool faceVerified,
  }) async {
    // Layer 1: GPS Geofence Check
    final geoResult = _geofencingService.verifyPresence(
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      venueLat: venueLat,
      venueLng: venueLng,
      gpsAccuracy: gpsAccuracy,
    );

    if (!geoResult.isWithinGeofence) {
      return AttendanceResult(
        success: false,
        failureReason: geoResult.message,
        failedAt: 'gps',
      );
    }

    // Layer 2: Face Recognition (result passed from UI)
    if (!faceVerified) {
      return const AttendanceResult(
        success: false,
        failureReason: 'Face verification failed — face not recognized.',
        failedAt: 'face',
      );
    }

    // Layer 3: Create composite verification record
    final record = AttendanceRecord(
      id: _uuid.v4(),
      meetingId: meetingId,
      villageId: villageId,
      memberId: member.id,
      memberName: member.nameMarathi,
      method: VerificationMethod.gpsFace,
      timestamp: DateTime.now(),
      gpsLatitude: deviceLat,
      gpsLongitude: deviceLng,
      gpsAccuracyMeters: gpsAccuracy,
      distanceFromVenueMeters: geoResult.distanceMeters,
      gpsVerified: true,
      faceMatchConfidence: faceMatchConfidence,
      faceVerified: true,
      gender: member.gender.name,
      category: member.category.name,
    );

    return AttendanceResult(
      success: true,
      record: record,
    );
  }

  /// Admin manual override for members without smartphones
  ///
  /// Creates an attendance record marked as manual entry.
  AttendanceRecord markManualAttendance({
    required VillageMember member,
    required String meetingId,
    required String villageId,
    required String adminUserId,
    required String reason,
  }) {
    return AttendanceRecord(
      id: _uuid.v4(),
      meetingId: meetingId,
      villageId: villageId,
      memberId: member.id,
      memberName: member.nameMarathi,
      method: VerificationMethod.manual,
      timestamp: DateTime.now(),
      gpsVerified: false,
      faceVerified: false,
      manualEntryByUserId: adminUserId,
      manualEntryReason: reason,
      gender: member.gender.name,
      category: member.category.name,
    );
  }
}

/// Result of an attendance attempt
class AttendanceResult {
  final bool success;
  final AttendanceRecord? record;
  final String? failureReason;
  final String? failedAt; // 'gps', 'face', 'other'

  const AttendanceResult({
    required this.success,
    this.record,
    this.failureReason,
    this.failedAt,
  });
}
