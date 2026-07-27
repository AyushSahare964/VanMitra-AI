import 'dart:math';
import '../core/constants/fra_constants.dart';

/// GPS-based proximity verification for Gram Sabha meeting attendance
///
/// Verifies that a member is physically present at the meeting venue
/// by checking their GPS coordinates against the venue location.
///
/// Uses Haversine formula for distance calculation on the Earth's surface.
class GeofencingService {
  /// Verify if the device is within the geofence radius of the meeting venue
  ///
  /// [deviceLat], [deviceLng] — current device GPS coordinates
  /// [venueLat], [venueLng] — meeting venue coordinates
  /// [radiusMeters] — geofence radius (default: 100m per FRA constants)
  ///
  /// Returns [GeofenceResult] with distance and verification status.
  GeofenceResult verifyPresence({
    required double deviceLat,
    required double deviceLng,
    required double venueLat,
    required double venueLng,
    double? radiusMeters,
    double? gpsAccuracy,
  }) {
    final radius = radiusMeters ?? FRAConstants.geofenceRadiusMeters;
    final distance = calculateDistance(deviceLat, deviceLng, venueLat, venueLng);

    final isWithinGeofence = distance <= radius;

    // Check GPS accuracy — unreliable if accuracy is worse than threshold
    final isAccuracyAcceptable = gpsAccuracy == null ||
        gpsAccuracy <= FRAConstants.minGpsAccuracyMeters;

    return GeofenceResult(
      isWithinGeofence: isWithinGeofence && isAccuracyAcceptable,
      distanceMeters: distance,
      radiusMeters: radius,
      gpsAccuracyMeters: gpsAccuracy,
      isAccuracyAcceptable: isAccuracyAcceptable,
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      venueLat: venueLat,
      venueLng: venueLng,
    );
  }

  /// Calculate distance between two GPS coordinates using Haversine formula
  ///
  /// Returns distance in meters.
  ///
  /// Haversine formula:
  ///   a = sin²(Δlat/2) + cos(lat1) · cos(lat2) · sin²(Δlng/2)
  ///   c = 2 · atan2(√a, √(1−a))
  ///   d = R · c
  ///
  /// where R = Earth's radius (6,371,000 meters)
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180.0;
}

/// Result of GPS geofence verification
class GeofenceResult {
  final bool isWithinGeofence;
  final double distanceMeters;
  final double radiusMeters;
  final double? gpsAccuracyMeters;
  final bool isAccuracyAcceptable;
  final double deviceLat;
  final double deviceLng;
  final double venueLat;
  final double venueLng;

  const GeofenceResult({
    required this.isWithinGeofence,
    required this.distanceMeters,
    required this.radiusMeters,
    this.gpsAccuracyMeters,
    required this.isAccuracyAcceptable,
    required this.deviceLat,
    required this.deviceLng,
    required this.venueLat,
    required this.venueLng,
  });

  /// Human-readable distance
  String get distanceDisplay {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  /// Status message
  String get message {
    if (!isAccuracyAcceptable) {
      return 'GPS signal too weak (accuracy: ${gpsAccuracyMeters?.toStringAsFixed(0)}m). '
          'Please move to an open area.';
    }
    if (isWithinGeofence) {
      return 'You are $distanceDisplay from the venue ✅';
    }
    return 'You are $distanceDisplay away ❌ — you must be within '
        '${radiusMeters.toStringAsFixed(0)}m of the meeting venue.';
  }
}
