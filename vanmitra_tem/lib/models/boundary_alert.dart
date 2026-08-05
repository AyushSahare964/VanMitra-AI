/// Satellite-based boundary change alert (Module B)
///
/// Extended with full field set from VanMitra_ModuleB_Ozar.ipynb output
/// (ozar_alerts.csv, Cell 21) — all new fields are nullable/optional so
/// existing documents without them continue to deserialise correctly.
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

  // Color helpers (mirrors AppColors palette)
  int get argbColor {
    switch (this) {
      case AlertTier.green:  return 0xFF2E7D32; // successGreen
      case AlertTier.yellow: return 0xFFF59E0B; // warningAmber
      case AlertTier.red:    return 0xFFDC2626; // alertRed
    }
  }
}

/// Resolution feasibility band — indicates how reliable the satellite
/// analysis is for this parcel given its size vs. the 10m pixel grid.
enum ResolutionFeasibility {
  reliable,
  marginal,
  unreliable,
}

extension ResolutionFeasibilityExt on ResolutionFeasibility {
  String get label {
    switch (this) {
      case ResolutionFeasibility.reliable:   return 'Reliable';
      case ResolutionFeasibility.marginal:   return 'Marginal';
      case ResolutionFeasibility.unreliable: return 'Unreliable';
    }
  }

  String get explainer {
    switch (this) {
      case ResolutionFeasibility.reliable:
        return 'Parcel is large enough for confident satellite analysis.';
      case ResolutionFeasibility.marginal:
        return 'This parcel is small relative to the 10m pixel grid — treat this alert as indicative and confirm on a field visit.';
      case ResolutionFeasibility.unreliable:
        return 'Parcel is too small for reliable satellite analysis — field verification required before any action.';
    }
  }

  bool get needsWarning => this != ResolutionFeasibility.reliable;
}

/// A boundary change alert detected by the Siamese CNN satellite monitoring pipeline.
///
/// Fields from ozar_alerts.csv (new in Module B §4.1) are all nullable to
/// remain backward-compatible with any existing documents in boundary_alerts.
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
  final double? ndviChange; // ΔNDVI value (legacy field)
  final String? imagerySource; // e.g. "Sentinel-2 L2A" or "synthetic"
  final DateTime? imageryDate;

  // Description
  final String description;
  final String? descriptionMr;

  // Actions taken
  final bool isReported;
  final String? reportedTo; // "District Office" / "NGO"
  final DateTime? reportedAt;

  // ── Module B §4.1 — new fields from ozar_alerts.csv ─────────────────────
  final int? landownerId;
  final String? claimantName;
  final int? surveyNo;
  final double? declaredAreaSqm;
  final String? landUseType;       // "Agricultural/Farmland" | "Domestic/Homestead"
  final ResolutionFeasibility? resolutionFeasibility;
  final double? areaAffectedSqm;
  final String? likelyCause;       // "No change detected" | "Illegal Clearing / Logging" | …
  final double? confidence;        // 0–1
  final double? ndviMean;          // −1–1
  final String? modelVersion;      // "demo-v1-synthetic" | "ee-v1"
  final String? boundarySource;    // "FALLBACK" | "OSM"

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
    // Module B fields
    this.landownerId,
    this.claimantName,
    this.surveyNo,
    this.declaredAreaSqm,
    this.landUseType,
    this.resolutionFeasibility,
    this.areaAffectedSqm,
    this.likelyCause,
    this.confidence,
    this.ndviMean,
    this.modelVersion,
    this.boundarySource,
  });

  bool get isResolved => resolvedAt != null;
  bool get isActive => !isResolved;

  /// True when this alert was produced from synthetic/demo data rather than
  /// real Sentinel-2 imagery via Earth Engine.
  bool get isSyntheticData =>
      modelVersion == 'demo-v1-synthetic' ||
      boundarySource == 'FALLBACK' ||
      imagerySource == 'synthetic';

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
    'landownerId': landownerId,
    'claimantName': claimantName,
    'surveyNo': surveyNo,
    'declaredAreaSqm': declaredAreaSqm,
    'landUseType': landUseType,
    'resolutionFeasibility': resolutionFeasibility?.name,
    'areaAffectedSqm': areaAffectedSqm,
    'likelyCause': likelyCause,
    'confidence': confidence,
    'ndviMean': ndviMean,
    'modelVersion': modelVersion,
    'boundarySource': boundarySource,
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
    landownerId: json['landownerId'] as int?,
    claimantName: json['claimantName'] as String?,
    surveyNo: json['surveyNo'] as int?,
    declaredAreaSqm: (json['declaredAreaSqm'] as num?)?.toDouble(),
    landUseType: json['landUseType'] as String?,
    resolutionFeasibility: json['resolutionFeasibility'] != null
        ? ResolutionFeasibility.values.byName(json['resolutionFeasibility'] as String)
        : null,
    areaAffectedSqm: (json['areaAffectedSqm'] as num?)?.toDouble(),
    likelyCause: json['likelyCause'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble(),
    ndviMean: (json['ndviMean'] as num?)?.toDouble(),
    modelVersion: json['modelVersion'] as String?,
    boundarySource: json['boundarySource'] as String?,
  );
}
