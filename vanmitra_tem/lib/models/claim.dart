import 'package:flutter/material.dart';
import 'package:vanmitra_ai/services/localization_service.dart';

/// FRA claim types
enum ClaimType {
  /// Form A — Individual Forest Right (IFR) under Sec. 3(1)(a)
  /// or Community Rights (CR) under Sec. 3(1)(b-d)
  formA,

  /// Form B — Community Forest Resource Right (CFRR) under Sec. 3(1)(i)
  formB,
}

/// Claim status lifecycle
enum ClaimStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  appealFiled,
}

extension ClaimStatusExtension on ClaimStatus {
  String get displayNameEn {
    switch (this) {
      case ClaimStatus.draft: return 'Draft';
      case ClaimStatus.submitted: return 'Submitted';
      case ClaimStatus.underReview: return 'Under Review';
      case ClaimStatus.approved: return 'Approved';
      case ClaimStatus.rejected: return 'Rejected';
      case ClaimStatus.appealFiled: return 'Appeal Filed';
    }
  }

  String get displayNameMr {
    switch (this) {
      case ClaimStatus.draft: return 'मसुदा';
      case ClaimStatus.submitted: return 'सादर';
      case ClaimStatus.underReview: return 'पुनरावलोकन';
      case ClaimStatus.approved: return 'मंजूर';
      case ClaimStatus.rejected: return 'नामंजूर';
      case ClaimStatus.appealFiled: return 'अपील दाखल';
    }
  }

  String getLocalizedStatus(BuildContext context) {
    switch (this) {
      case ClaimStatus.draft: return context.tr('claim_status_draft');
      case ClaimStatus.submitted: return context.tr('claim_status_submitted');
      case ClaimStatus.underReview: return context.tr('claim_status_under_review');
      case ClaimStatus.approved: return context.tr('claim_status_approved');
      case ClaimStatus.rejected: return context.tr('claim_status_rejected');
      case ClaimStatus.appealFiled: return context.tr('claim_status_appeal');
    }
  }

  String get icon {
    switch (this) {
      case ClaimStatus.draft: return '📝';
      case ClaimStatus.submitted: return '📤';
      case ClaimStatus.underReview: return '🔍';
      case ClaimStatus.approved: return '✅';
      case ClaimStatus.rejected: return '❌';
      case ClaimStatus.appealFiled: return '🔄';
    }
  }
}

/// Nature of the claimed right
enum ClaimNature {
  cultivation,
  habitation,
  mfpCollection,
  grazing,
  waterBodies,
  traditionalResource,
  other,
}

extension ClaimNatureExtension on ClaimNature {
  String get displayNameEn {
    switch (this) {
      case ClaimNature.cultivation: return 'Cultivation';
      case ClaimNature.habitation: return 'Habitation';
      case ClaimNature.mfpCollection: return 'MFP Collection';
      case ClaimNature.grazing: return 'Grazing';
      case ClaimNature.waterBodies: return 'Water Bodies';
      case ClaimNature.traditionalResource: return 'Traditional Resource';
      case ClaimNature.other: return 'Other';
    }
  }

  String get displayNameMr {
    switch (this) {
      case ClaimNature.cultivation: return 'शेती';
      case ClaimNature.habitation: return 'निवास';
      case ClaimNature.mfpCollection: return 'गौण वनोपज संकलन';
      case ClaimNature.grazing: return 'चराई';
      case ClaimNature.waterBodies: return 'जलस्रोत';
      case ClaimNature.traditionalResource: return 'पारंपरिक संसाधन';
      case ClaimNature.other: return 'इतर';
    }
  }

  String getLocalizedNature(BuildContext context) {
    switch (this) {
      case ClaimNature.cultivation: return context.tr('claim_nature_cultivation');
      case ClaimNature.habitation: return context.tr('claim_nature_habitation');
      case ClaimNature.mfpCollection: return context.tr('claim_nature_mfpCollection');
      case ClaimNature.grazing: return context.tr('claim_nature_grazing');
      case ClaimNature.waterBodies: return context.tr('claim_nature_waterBodies');
      case ClaimNature.traditionalResource: return context.tr('claim_nature_traditionalResource');
      case ClaimNature.other: return context.tr('claim_nature_other');
    }
  }
}

/// An FRA claim (Form A or Form B)
class Claim {
  final String id;
  final String claimantUserId;
  final String villageId;
  final ClaimType type;
  final ClaimStatus status;
  final ClaimNature nature;

  // Claimant details
  final String claimantName;
  final String claimantNameEn;
  final String? fatherHusbandName;
  final String? address;

  // Land details
  final String? surveyNumber;
  final double? areaSqMeters;
  final String? landDescription;

  // Occupation details
  final int? occupationYears;
  final bool occupationBefore2005; // Before 13.12.2005

  // Evidence
  final Map<String, bool> evidenceFlags; // category -> present/absent
  final double evidenceScore; // E ∈ [0, 1]
  final List<String> missingEvidence;

  // Dates
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? appealDeadline; // rejectedAt + 60 days

  // Sync
  final bool isSynced;

  const Claim({
    required this.id,
    required this.claimantUserId,
    required this.villageId,
    required this.type,
    required this.status,
    required this.nature,
    required this.claimantName,
    required this.claimantNameEn,
    this.fatherHusbandName,
    this.address,
    this.surveyNumber,
    this.areaSqMeters,
    this.landDescription,
    this.occupationYears,
    this.occupationBefore2005 = true,
    this.evidenceFlags = const {},
    this.evidenceScore = 0.0,
    this.missingEvidence = const [],
    required this.createdAt,
    this.submittedAt,
    this.reviewedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.appealDeadline,
    this.isSynced = false,
  });

  /// Whether appeal window is still open (within 60 days of rejection)
  bool get isAppealWindowOpen {
    if (appealDeadline == null) return false;
    return DateTime.now().isBefore(appealDeadline!);
  }

  /// Days remaining in appeal window
  int get appealDaysRemaining {
    if (appealDeadline == null) return 0;
    final diff = appealDeadline!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Evidence score tier
  String get evidenceTier {
    if (evidenceScore >= 0.8) return 'green';
    if (evidenceScore >= 0.6) return 'yellow';
    return 'red';
  }

  Claim copyWith({
    ClaimStatus? status,
    Map<String, bool>? evidenceFlags,
    double? evidenceScore,
    List<String>? missingEvidence,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? appealDeadline,
    bool? isSynced,
    String? claimantName,
    String? claimantNameEn,
    String? fatherHusbandName,
    String? address,
    String? surveyNumber,
    double? areaSqMeters,
    String? landDescription,
    int? occupationYears,
    bool? occupationBefore2005,
    ClaimNature? nature,
  }) {
    return Claim(
      id: id,
      claimantUserId: claimantUserId,
      villageId: villageId,
      type: type,
      status: status ?? this.status,
      nature: nature ?? this.nature,
      claimantName: claimantName ?? this.claimantName,
      claimantNameEn: claimantNameEn ?? this.claimantNameEn,
      fatherHusbandName: fatherHusbandName ?? this.fatherHusbandName,
      address: address ?? this.address,
      surveyNumber: surveyNumber ?? this.surveyNumber,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      landDescription: landDescription ?? this.landDescription,
      occupationYears: occupationYears ?? this.occupationYears,
      occupationBefore2005: occupationBefore2005 ?? this.occupationBefore2005,
      evidenceFlags: evidenceFlags ?? this.evidenceFlags,
      evidenceScore: evidenceScore ?? this.evidenceScore,
      missingEvidence: missingEvidence ?? this.missingEvidence,
      createdAt: createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      appealDeadline: appealDeadline ?? this.appealDeadline,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'claimantUserId': claimantUserId,
    'villageId': villageId,
    'type': type.name,
    'status': status.name,
    'nature': nature.name,
    'claimantName': claimantName,
    'claimantNameEn': claimantNameEn,
    'fatherHusbandName': fatherHusbandName,
    'address': address,
    'surveyNumber': surveyNumber,
    'areaSqMeters': areaSqMeters,
    'landDescription': landDescription,
    'occupationYears': occupationYears,
    'occupationBefore2005': occupationBefore2005,
    'evidenceFlags': evidenceFlags,
    'evidenceScore': evidenceScore,
    'missingEvidence': missingEvidence,
    'createdAt': createdAt.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'rejectedAt': rejectedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'appealDeadline': appealDeadline?.toIso8601String(),
    'isSynced': isSynced,
  };

  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
    id: json['id'] as String,
    claimantUserId: json['claimantUserId'] as String,
    villageId: json['villageId'] as String,
    type: ClaimType.values.byName(json['type'] as String),
    status: ClaimStatus.values.byName(json['status'] as String),
    nature: ClaimNature.values.byName(json['nature'] as String),
    claimantName: json['claimantName'] as String,
    claimantNameEn: json['claimantNameEn'] as String,
    fatherHusbandName: json['fatherHusbandName'] as String?,
    address: json['address'] as String?,
    surveyNumber: json['surveyNumber'] as String?,
    areaSqMeters: (json['areaSqMeters'] as num?)?.toDouble(),
    landDescription: json['landDescription'] as String?,
    occupationYears: json['occupationYears'] as int?,
    occupationBefore2005: json['occupationBefore2005'] as bool? ?? true,
    evidenceFlags: (json['evidenceFlags'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)) ??
        const {},
    evidenceScore: (json['evidenceScore'] as num?)?.toDouble() ?? 0.0,
    missingEvidence: (json['missingEvidence'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    submittedAt: json['submittedAt'] != null
        ? DateTime.parse(json['submittedAt'] as String)
        : null,
    reviewedAt: json['reviewedAt'] != null
        ? DateTime.parse(json['reviewedAt'] as String)
        : null,
    rejectedAt: json['rejectedAt'] != null
        ? DateTime.parse(json['rejectedAt'] as String)
        : null,
    rejectionReason: json['rejectionReason'] as String?,
    appealDeadline: json['appealDeadline'] != null
        ? DateTime.parse(json['appealDeadline'] as String)
        : null,
    isSynced: json['isSynced'] as bool? ?? false,
  );
}
