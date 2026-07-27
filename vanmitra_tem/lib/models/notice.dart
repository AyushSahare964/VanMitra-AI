/// Notice categories — matches the VanMitra spec (B.3) exactly
enum NoticeCategory {
  meetingSchedule,
  claimDeadline,
  documentRequirement,
  portalDowntime,
  general,
}

extension NoticeCategoryExtension on NoticeCategory {
  String get displayNameMr {
    switch (this) {
      case NoticeCategory.meetingSchedule:
        return 'ग्रामसभा सूचना';
      case NoticeCategory.claimDeadline:
        return 'दावा अंतिम मुदत';
      case NoticeCategory.documentRequirement:
        return 'कागदपत्र आवश्यकता';
      case NoticeCategory.portalDowntime:
        return 'पोर्टल बंद';
      case NoticeCategory.general:
        return 'सामान्य सूचना';
    }
  }

  String get displayNameEn {
    switch (this) {
      case NoticeCategory.meetingSchedule:
        return 'Meeting Schedule';
      case NoticeCategory.claimDeadline:
        return 'Claim Deadline';
      case NoticeCategory.documentRequirement:
        return 'Document Requirement';
      case NoticeCategory.portalDowntime:
        return 'Portal Downtime';
      case NoticeCategory.general:
        return 'General Notice';
    }
  }
}

/// Severity drives the ticker color:
///   info → govt-blue, warning → amber, critical → red
enum NoticeSeverity { info, warning, critical }

/// Source distinguishes admin-typed vs system-auto-generated notices
enum NoticeSource { adminPosted, systemGenerated }

/// A VanMitra notice — displayed in the MAHA-DBT style notice ticker + board.
///
/// Stored in Hive box 'notices'. Synced to the FastAPI backend when online
/// (same sync-queue pattern as meetings/resolutions).
class Notice {
  final String noticeId;
  final NoticeCategory category;

  /// Localized title: { "mr": "...", "en": "...", "hi": "...", "kn": "..." }
  final Map<String, String> titleByLang;

  /// Localized body text
  final Map<String, String> bodyByLang;

  final NoticeSeverity severity;
  final DateTime validFrom;
  final DateTime validUntil;

  /// Deep-link into MeetingDetailScreen (if relevant)
  final String? linkedMeetingId;

  /// Deep-link into ClaimListScreen / ClaimTrackingScreen (if relevant)
  final String? linkedClaimId;

  final NoticeSource source;
  final bool isDismissed;
  final DateTime createdAt;

  const Notice({
    required this.noticeId,
    required this.category,
    required this.titleByLang,
    required this.bodyByLang,
    required this.severity,
    required this.validFrom,
    required this.validUntil,
    this.linkedMeetingId,
    this.linkedClaimId,
    required this.source,
    this.isDismissed = false,
    required this.createdAt,
  });

  /// Is this notice currently visible (within its validity window)?
  bool get isActive {
    final now = DateTime.now();
    return !isDismissed && now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  /// Title in the given language, falling back to English
  String titleFor(String lang) =>
      titleByLang[lang] ?? titleByLang['en'] ?? '';

  /// Body in the given language, falling back to English
  String bodyFor(String lang) =>
      bodyByLang[lang] ?? bodyByLang['en'] ?? '';

  Notice copyWith({bool? isDismissed}) {
    return Notice(
      noticeId: noticeId,
      category: category,
      titleByLang: titleByLang,
      bodyByLang: bodyByLang,
      severity: severity,
      validFrom: validFrom,
      validUntil: validUntil,
      linkedMeetingId: linkedMeetingId,
      linkedClaimId: linkedClaimId,
      source: source,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'noticeId': noticeId,
        'category': category.name,
        'titleByLang': titleByLang,
        'bodyByLang': bodyByLang,
        'severity': severity.name,
        'validFrom': validFrom.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'linkedMeetingId': linkedMeetingId,
        'linkedClaimId': linkedClaimId,
        'source': source.name,
        'isDismissed': isDismissed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        noticeId: json['noticeId'] as String,
        category: NoticeCategory.values.byName(json['category'] as String),
        titleByLang: Map<String, String>.from(json['titleByLang'] as Map),
        bodyByLang: Map<String, String>.from(json['bodyByLang'] as Map),
        severity: NoticeSeverity.values.byName(json['severity'] as String),
        validFrom: DateTime.parse(json['validFrom'] as String),
        validUntil: DateTime.parse(json['validUntil'] as String),
        linkedMeetingId: json['linkedMeetingId'] as String?,
        linkedClaimId: json['linkedClaimId'] as String?,
        source: NoticeSource.values.byName(json['source'] as String),
        isDismissed: json['isDismissed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
