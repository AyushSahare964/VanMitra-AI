/// Method used to verify attendance
enum VerificationMethod {
  /// GPS geofence + Face recognition (self check-in)
  gpsFace,

  /// Admin marked manually (for members without smartphones / elderly)
  manual,

  /// OTP-based check-in (future)
  otp,
}

/// Individual attendance record for a Gram Sabha meeting
/// Captures the composite verification proof
///
/// FIX (Problem 8): Added `villageId` field.
/// The Firestore security rule for attendance_records requires
/// sameVillage(request.resource.data.villageId). Without this field,
/// every attendance write was silently denied with permission-denied.
class AttendanceRecord {
  final String id;
  final String meetingId;
  final String memberId;
  final String memberName;
  final String villageId; // FIX: required by Firestore security rule
  final VerificationMethod method;
  final DateTime timestamp;

  // GPS verification data
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAccuracyMeters;
  final double? distanceFromVenueMeters;
  final bool gpsVerified;

  // Face verification data
  final double? faceMatchConfidence;
  final bool faceVerified;

  // Manual entry data (when method == manual)
  final String? manualEntryByUserId;
  final String? manualEntryReason;

  // Member demographics (snapshot at time of attendance)
  final String gender; // 'male', 'female', 'other'
  final String category; // 'st', 'pvtg', 'otfd', 'general'

  const AttendanceRecord({
    required this.id,
    required this.meetingId,
    required this.memberId,
    required this.memberName,
    required this.villageId, // FIX: now required
    required this.method,
    required this.timestamp,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAccuracyMeters,
    this.distanceFromVenueMeters,
    this.gpsVerified = false,
    this.faceMatchConfidence,
    this.faceVerified = false,
    this.manualEntryByUserId,
    this.manualEntryReason,
    required this.gender,
    required this.category,
  });

  /// Whether this attendance was fully verified (GPS + Face)
  bool get isFullyVerified => gpsVerified && faceVerified;

  /// Whether this member is a woman (for quorum W/A check)
  bool get isWoman => gender == 'female';

  /// Whether this member is ST
  bool get isST => category == 'st';

  /// Whether this member is PVTG
  bool get isPVTG => category == 'pvtg';

  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingId': meetingId,
    'memberId': memberId,
    'memberName': memberName,
    'villageId': villageId, // FIX: included in toJson
    'method': method.name,
    'timestamp': timestamp.toIso8601String(),
    'gpsLatitude': gpsLatitude,
    'gpsLongitude': gpsLongitude,
    'gpsAccuracyMeters': gpsAccuracyMeters,
    'distanceFromVenueMeters': distanceFromVenueMeters,
    'gpsVerified': gpsVerified,
    'faceMatchConfidence': faceMatchConfidence,
    'faceVerified': faceVerified,
    'manualEntryByUserId': manualEntryByUserId,
    'manualEntryReason': manualEntryReason,
    'gender': gender,
    'category': category,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        meetingId: json['meetingId'] as String,
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        villageId: json['villageId'] as String? ?? '', // FIX: read from json
        method: VerificationMethod.values.byName(json['method'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
        gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
        gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num?)?.toDouble(),
        distanceFromVenueMeters:
            (json['distanceFromVenueMeters'] as num?)?.toDouble(),
        gpsVerified: json['gpsVerified'] as bool? ?? false,
        faceMatchConfidence:
            (json['faceMatchConfidence'] as num?)?.toDouble(),
        faceVerified: json['faceVerified'] as bool? ?? false,
        manualEntryByUserId: json['manualEntryByUserId'] as String?,
        manualEntryReason: json['manualEntryReason'] as String?,
        gender: json['gender'] as String,
        category: json['category'] as String,
      );
}

