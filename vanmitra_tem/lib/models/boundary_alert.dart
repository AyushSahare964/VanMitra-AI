/// Satellite-based boundary change alert (Module B)
///
/// Represents a detected change in the CFR boundary area
/// from the NDVI change-detection pipeline.
///
/// Alert tiers per VanMitra-AI Technical Report Sec. 14.2:
///   🟢 Green — No significant change, boundary stable
///   🟡 Yellow — Localised change, possible natural/seasonal variation
///   🔴 Red — ΔNDVI < −θ, probable unauthorised activity
enum AlertTier {
  green,
  yellow,
  red,
}

extension AlertTierExtension on AlertTier {
  String get displayNameEn {
    switch (this) {
      case AlertTier.green: return 'Stable';
      case AlertTier.yellow: return 'Minor Change';
      case AlertTier.red: return 'Critical Alert';
    }
  }

  String get displayNameMr {
    switch (this) {
      case AlertTier.green: return 'स्थिर';
      case AlertTier.yellow: return 'किरकोळ बदल';
      case AlertTier.red: return 'गंभीर इशारा';
    }
  }

  String get emoji {
    switch (this) {
      case AlertTier.green: return '🟢';
      case AlertTier.yellow: return '🟡';
      case AlertTier.red: return '🔴';
    }
  }

  String get actionEn {
    switch (this) {
      case AlertTier.green:
        return 'No action — routine monitoring continues';
      case AlertTier.yellow:
        return 'Logged for weekly batch review';
      case AlertTier.red:
        return 'Immediate alert to Gram Sabha and linked NGO';
    }
  }
}

/// A boundary change alert detected by the satellite monitoring pipeline
class BoundaryAlert {
  final String id;
  final String villageId;
  final AlertTier tier;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  // Location of the detected change
  final double latitude;
  final double longitude;
  final double? affectedAreaSqMeters;

  // NDVI change data
  final double? ndviChange; // ΔNDVI value
  final String? imagerySource; // e.g. "Sentinel-2 L2A"
  final DateTime? imageryDate;

  // Description
  final String description;
  final String? descriptionMr;

  // Actions taken
  final bool isReported;
  final String? reportedTo; // "District Office" / "NGO"
  final DateTime? reportedAt;

  const BoundaryAlert({
    required this.id,
    required this.villageId,
    required this.tier,
    required this.detectedAt,
    this.resolvedAt,
    required this.latitude,
    required this.longitude,
    this.affectedAreaSqMeters,
    this.ndviChange,
    this.imagerySource,
    this.imageryDate,
    required this.description,
    this.descriptionMr,
    this.isReported = false,
    this.reportedTo,
    this.reportedAt,
  });

  bool get isResolved => resolvedAt != null;
  bool get isActive => !isResolved;

  Map<String, dynamic> toJson() => {
    'id': id,
    'villageId': villageId,
    'tier': tier.name,
    'detectedAt': detectedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'affectedAreaSqMeters': affectedAreaSqMeters,
    'ndviChange': ndviChange,
    'imagerySource': imagerySource,
    'imageryDate': imageryDate?.toIso8601String(),
    'description': description,
    'descriptionMr': descriptionMr,
    'isReported': isReported,
    'reportedTo': reportedTo,
    'reportedAt': reportedAt?.toIso8601String(),
  };

  factory BoundaryAlert.fromJson(Map<String, dynamic> json) => BoundaryAlert(
    id: json['id'] as String,
    villageId: json['villageId'] as String,
    tier: AlertTier.values.byName(json['tier'] as String),
    detectedAt: DateTime.parse(json['detectedAt'] as String),
    resolvedAt: json['resolvedAt'] != null
        ? DateTime.parse(json['resolvedAt'] as String)
        : null,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    affectedAreaSqMeters: (json['affectedAreaSqMeters'] as num?)?.toDouble(),
    ndviChange: (json['ndviChange'] as num?)?.toDouble(),
    imagerySource: json['imagerySource'] as String?,
    imageryDate: json['imageryDate'] != null
        ? DateTime.parse(json['imageryDate'] as String)
        : null,
    description: json['description'] as String,
    descriptionMr: json['descriptionMr'] as String?,
    isReported: json['isReported'] as bool? ?? false,
    reportedTo: json['reportedTo'] as String?,
    reportedAt: json['reportedAt'] != null
        ? DateTime.parse(json['reportedAt'] as String)
        : null,
  );
}
