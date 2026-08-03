import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of Gram Sabha meetings
/// Aligned with FRA provisions
enum MeetingType {
  /// Regular Gram Sabha meeting (नियमित)
  regular,

  /// Special meeting called for specific agenda (विशेष)
  special,

  /// Consent resolution meeting — requires enhanced quorum
  /// Per 2009 MoEFCC Circular: consent before forest diversion under FCA 1980
  consentResolution,
}

extension MeetingTypeExtension on MeetingType {
  String get displayNameEn {
    switch (this) {
      case MeetingType.regular:
        return 'Regular Meeting';
      case MeetingType.special:
        return 'Special Meeting';
      case MeetingType.consentResolution:
        return 'Consent Resolution Meeting';
    }
  }

  String get displayNameMr {
    switch (this) {
      case MeetingType.regular:
        return 'नियमित सभा';
      case MeetingType.special:
        return 'विशेष सभा';
      case MeetingType.consentResolution:
        return 'संमती ठराव सभा';
    }
  }

  /// Whether this meeting type requires enhanced quorum checks
  bool get requiresEnhancedQuorum => this == MeetingType.consentResolution;
}

/// Status of a Gram Sabha meeting
enum MeetingStatus {
  /// Meeting is scheduled but not yet started
  scheduled,

  /// Meeting is currently in progress (attendance being marked)
  inProgress,

  /// Meeting completed, resolutions recorded
  completed,

  /// Meeting cancelled
  cancelled,
}

/// Gram Sabha meeting record
class GramSabhaMeeting {
  final String id;
  final String villageId;
  final DateTime scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final MeetingType type;
  final MeetingStatus status;
  final String venue;
  final double venueLat;
  final double venueLng;
  final String? agenda;
  final String createdByUserId;
  final List<String> resolutionIds; // References to resolutions recorded
  final int totalAttendees;
  final int womenAttendees;
  final int stAttendees;
  final int pvtgAttendees;
  final bool quorumValid;

  const GramSabhaMeeting({
    required this.id,
    required this.villageId,
    required this.scheduledDate,
    this.startedAt,
    this.completedAt,
    required this.type,
    required this.status,
    required this.venue,
    required this.venueLat,
    required this.venueLng,
    this.agenda,
    required this.createdByUserId,
    this.resolutionIds = const [],
    this.totalAttendees = 0,
    this.womenAttendees = 0,
    this.stAttendees = 0,
    this.pvtgAttendees = 0,
    this.quorumValid = false,
  });

  /// Whether this meeting is currently accepting attendance
  bool get isAcceptingAttendance =>
      status == MeetingStatus.scheduled || status == MeetingStatus.inProgress;

  /// Whether this meeting is active today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// Whether this is an upcoming meeting
  bool get isUpcoming =>
      status == MeetingStatus.scheduled &&
      scheduledDate.isAfter(DateTime.now());

  GramSabhaMeeting copyWith({
    DateTime? startedAt,
    DateTime? completedAt,
    MeetingStatus? status,
    String? agenda,
    List<String>? resolutionIds,
    int? totalAttendees,
    int? womenAttendees,
    int? stAttendees,
    int? pvtgAttendees,
    bool? quorumValid,
  }) {
    return GramSabhaMeeting(
      id: id,
      villageId: villageId,
      scheduledDate: scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      type: type,
      status: status ?? this.status,
      venue: venue,
      venueLat: venueLat,
      venueLng: venueLng,
      agenda: agenda ?? this.agenda,
      createdByUserId: createdByUserId,
      resolutionIds: resolutionIds ?? this.resolutionIds,
      totalAttendees: totalAttendees ?? this.totalAttendees,
      womenAttendees: womenAttendees ?? this.womenAttendees,
      stAttendees: stAttendees ?? this.stAttendees,
      pvtgAttendees: pvtgAttendees ?? this.pvtgAttendees,
      quorumValid: quorumValid ?? this.quorumValid,
    );
  }

  /// Serialise for **Hive** local storage (ISO-8601 date strings).
  Map<String, dynamic> toJson() => {
    'id': id,
    'villageId': villageId,
    'scheduledDate': scheduledDate.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'type': type.name,
    'status': status.name,
    'venue': venue,
    'venueLat': venueLat,
    'venueLng': venueLng,
    'agenda': agenda,
    'createdByUserId': createdByUserId,
    'resolutionIds': resolutionIds,
    'totalAttendees': totalAttendees,
    'womenAttendees': womenAttendees,
    'stAttendees': stAttendees,
    'pvtgAttendees': pvtgAttendees,
    'quorumValid': quorumValid,
  };

  /// Serialise for **Firestore** — uses native Timestamp objects.
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'villageId': villageId,
    'scheduledDate': Timestamp.fromDate(scheduledDate),
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'type': type.name,
    'status': status.name,
    'venue': venue,
    'venueLat': venueLat,
    'venueLng': venueLng,
    'agenda': agenda,
    'createdByUserId': createdByUserId,
    'resolutionIds': resolutionIds,
    'totalAttendees': totalAttendees,
    'womenAttendees': womenAttendees,
    'stAttendees': stAttendees,
    'pvtgAttendees': pvtgAttendees,
    'quorumValid': quorumValid,
  };

  /// Parse a DateTime from either a Firestore [Timestamp] or an ISO-8601 [String].
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Cannot parse date from $value');
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    return _parseDate(value);
  }

  factory GramSabhaMeeting.fromJson(Map<String, dynamic> json) =>
      GramSabhaMeeting(
        id: json['id'] as String,
        villageId: json['villageId'] as String,
        scheduledDate: _parseDate(json['scheduledDate']),
        startedAt: _parseDateOrNull(json['startedAt']),
        completedAt: _parseDateOrNull(json['completedAt']),
        type: MeetingType.values.byName(json['type'] as String),
        status: MeetingStatus.values.byName(json['status'] as String),
        venue: json['venue'] as String,
        venueLat: (json['venueLat'] as num).toDouble(),
        venueLng: (json['venueLng'] as num).toDouble(),
        agenda: json['agenda'] as String?,
        createdByUserId: json['createdByUserId'] as String,
        resolutionIds: (json['resolutionIds'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        totalAttendees: json['totalAttendees'] as int? ?? 0,
        womenAttendees: json['womenAttendees'] as int? ?? 0,
        stAttendees: json['stAttendees'] as int? ?? 0,
        pvtgAttendees: json['pvtgAttendees'] as int? ?? 0,
        quorumValid: json['quorumValid'] as bool? ?? false,
      );
}
