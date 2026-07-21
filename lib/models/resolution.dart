/// Types of resolutions aligned with FRA provisions
enum ResolutionType {
  /// Approval of FRA claim — Gram Sabha verifies and approves
  claimApproval,

  /// Community Forest Resource management resolution
  cfrManagement,

  /// Consent for diversion of forest land under FCA 1980
  /// Requires enhanced quorum per 2009 MoEFCC Circular
  consentForDiversion,

  /// Minor Forest Produce sale/transit resolution
  mfpSaleTransit,

  /// General resolution
  other,
}

extension ResolutionTypeExtension on ResolutionType {
  String get displayNameEn {
    switch (this) {
      case ResolutionType.claimApproval:
        return 'Claim Approval';
      case ResolutionType.cfrManagement:
        return 'CFR Management';
      case ResolutionType.consentForDiversion:
        return 'Consent for Forest Diversion';
      case ResolutionType.mfpSaleTransit:
        return 'MFP Sale/Transit';
      case ResolutionType.other:
        return 'Other';
    }
  }

  String get displayNameMr {
    switch (this) {
      case ResolutionType.claimApproval:
        return 'दावा मंजूरी';
      case ResolutionType.cfrManagement:
        return 'सामुदायिक वन संसाधन व्यवस्थापन';
      case ResolutionType.consentForDiversion:
        return 'वनभूमी वळती संमती';
      case ResolutionType.mfpSaleTransit:
        return 'गौण वनोपज विक्री/पारगमन';
      case ResolutionType.other:
        return 'इतर';
    }
  }

  /// Whether this resolution type requires enhanced quorum
  bool get requiresEnhancedQuorum =>
      this == ResolutionType.consentForDiversion;

  /// Relevant FRA/FCA section reference
  String get legalReference {
    switch (this) {
      case ResolutionType.claimApproval:
        return 'FRA 2006, Sec. 6(1) — Gram Sabha verification';
      case ResolutionType.cfrManagement:
        return 'FRA 2006, Sec. 3(1)(i) — CFR management';
      case ResolutionType.consentForDiversion:
        return 'FCA 1980 + 2009 MoEFCC Circular — Gram Sabha consent required';
      case ResolutionType.mfpSaleTransit:
        return 'FRA 2006, Sec. 3(1)(c) — MFP rights';
      case ResolutionType.other:
        return 'PESA 1996 — Gram Sabha powers';
    }
  }
}

/// A resolution recorded during a Gram Sabha meeting
/// Part of the tamper-evident hash-chain ledger
class Resolution {
  final String id;
  final String meetingId;
  final String villageId;
  final ResolutionType type;
  final String text; // Resolution text (Marathi/English)
  final String? summary;
  final DateTime timestamp;
  final String recordedByUserId;

  // Quorum snapshot at time of resolution
  final bool quorumValid;
  final int totalPresent;
  final int totalRegistered;
  final int womenPresent;
  final int stPresent;
  final int pvtgPresent;
  final double attendancePercentage;
  final double womenPercentage;

  // Hash chain data
  final String hash; // Hₙ = SHA256(Hₙ₋₁ ∥ Dₙ ∥ tₙ)
  final String previousHash; // Hₙ₋₁
  final int blockIndex; // Position in chain (0 = genesis)

  // Related claim reference (if claimApproval)
  final String? relatedClaimId;

  // Compliance flag
  final bool isCompliant; // quorumValid AND (if consent → enhanced quorum met)

  const Resolution({
    required this.id,
    required this.meetingId,
    required this.villageId,
    required this.type,
    required this.text,
    this.summary,
    required this.timestamp,
    required this.recordedByUserId,
    required this.quorumValid,
    required this.totalPresent,
    required this.totalRegistered,
    required this.womenPresent,
    this.stPresent = 0,
    this.pvtgPresent = 0,
    required this.attendancePercentage,
    required this.womenPercentage,
    required this.hash,
    required this.previousHash,
    required this.blockIndex,
    this.relatedClaimId,
    required this.isCompliant,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingId': meetingId,
    'villageId': villageId,
    'type': type.name,
    'text': text,
    'summary': summary,
    'timestamp': timestamp.toIso8601String(),
    'recordedByUserId': recordedByUserId,
    'quorumValid': quorumValid,
    'totalPresent': totalPresent,
    'totalRegistered': totalRegistered,
    'womenPresent': womenPresent,
    'stPresent': stPresent,
    'pvtgPresent': pvtgPresent,
    'attendancePercentage': attendancePercentage,
    'womenPercentage': womenPercentage,
    'hash': hash,
    'previousHash': previousHash,
    'blockIndex': blockIndex,
    'relatedClaimId': relatedClaimId,
    'isCompliant': isCompliant,
  };

  factory Resolution.fromJson(Map<String, dynamic> json) => Resolution(
    id: json['id'] as String,
    meetingId: json['meetingId'] as String,
    villageId: json['villageId'] as String,
    type: ResolutionType.values.byName(json['type'] as String),
    text: json['text'] as String,
    summary: json['summary'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    recordedByUserId: json['recordedByUserId'] as String,
    quorumValid: json['quorumValid'] as bool,
    totalPresent: json['totalPresent'] as int,
    totalRegistered: json['totalRegistered'] as int,
    womenPresent: json['womenPresent'] as int,
    stPresent: json['stPresent'] as int? ?? 0,
    pvtgPresent: json['pvtgPresent'] as int? ?? 0,
    attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
    womenPercentage: (json['womenPercentage'] as num).toDouble(),
    hash: json['hash'] as String,
    previousHash: json['previousHash'] as String,
    blockIndex: json['blockIndex'] as int,
    relatedClaimId: json['relatedClaimId'] as String?,
    isCompliant: json['isCompliant'] as bool,
  );

  /// Data payload used for hash computation: Dₙ
  /// Contains all critical fields that must be tamper-evident
  String get hashPayload {
    return '${type.name}|$text|$totalPresent/$totalRegistered|'
        'W:$womenPresent|ST:$stPresent|PVTG:$pvtgPresent|'
        'Q:$quorumValid|C:$isCompliant';
  }
}
