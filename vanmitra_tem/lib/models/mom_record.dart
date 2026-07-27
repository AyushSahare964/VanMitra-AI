import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Module C — Minutes of Meeting record (Dₙ)
///
/// Represents the tamper-evident MoM payload assembled after a Gram Sabha session.
/// [toCanonicalJson] produces deterministic sorted-key JSON — identical on every call
/// with the same data — so the Dart provisional hash and Firestore canonical hash are
/// always reproducible from the same bytes.
class MomRecord {
  final String id;
  final String meetingId;
  final String villageId;

  /// ISO-8601 string e.g. "2026-07-10T10:45:00.000Z"
  final String meetingDate;

  /// GPS coordinates as "lat,lng" e.g. "19.7800,73.2200"
  final String geotag;

  // ── Multilingual resolution text ──────────────────────────────────────────
  final String decisionTextEn;
  final String decisionTextHi;
  final String decisionTextMr;

  /// Source language of the spoken resolution ('mr' | 'hi' | 'gon' | 'wbr')
  final String sourceLanguage;

  // ── Attendance & quorum snapshot ──────────────────────────────────────────
  /// A — total attendees verified at this meeting
  final int attendeeCount;

  /// R — total registered adult members on the village roll
  final int registeredCount;

  /// W — women attendees
  final int womenCount;

  /// Q_valid = (A/R ≥ 0.5) AND (W/A ≥ 1/3)
  final bool quorumValid;

  /// Human-readable quorum explanation (§7 explainability)
  final String quorumExplanation;

  /// How many attendees were verified by face-matching vs manual entry
  final int faceMatchedCount;
  final int manualAddedCount;

  // ── Hash chain fields ─────────────────────────────────────────────────────
  /// Provisional client-side SHA-256 hash (set offline immediately)
  final String localHash;

  /// Canonical hash assigned by Firestore after sync (null until synced)
  final String? canonicalHash;

  /// Device timestamp at the moment of MoM assembly (UTC ISO-8601)
  final String timestampUtc;

  /// Firestore server timestamp as canonical tₙ (set after publish)
  final String? firestoreTimestamp;

  /// Path to group photo saved on-device (null if not captured)
  final String? groupPhotoLocalPath;

  /// True once this record has been successfully published to Firestore
  final bool isSynced;

  const MomRecord({
    required this.id,
    required this.meetingId,
    required this.villageId,
    required this.meetingDate,
    required this.geotag,
    required this.decisionTextEn,
    required this.decisionTextHi,
    required this.decisionTextMr,
    required this.sourceLanguage,
    required this.attendeeCount,
    required this.registeredCount,
    required this.womenCount,
    required this.quorumValid,
    required this.quorumExplanation,
    required this.faceMatchedCount,
    required this.manualAddedCount,
    required this.localHash,
    required this.timestampUtc,
    this.canonicalHash,
    this.firestoreTimestamp,
    this.groupPhotoLocalPath,
    this.isSynced = false,
  });

  // ── Canonical JSON for hashing ─────────────────────────────────────────────
  /// Deterministic sorted-key map — MUST sort keys so the Dart provisional hash
  /// and the Firestore canonical hash are reproducible from identical bytes.
  Map<String, dynamic> toCanonicalJson() {
    final raw = <String, dynamic>{
      'decision_text_en': decisionTextEn,
      'decision_text_hi': decisionTextHi,
      'decision_text_mr': decisionTextMr,
      'geotag': geotag,
      'group_photo_path': groupPhotoLocalPath,
      'meeting_date': meetingDate,
      'quorum': {
        'A': attendeeCount,
        'R': registeredCount,
        'W': womenCount,
        'Q_valid': quorumValid,
      },
      'source_language': sourceLanguage,
      'village_id': villageId,
    };
    return _sortedMap(raw);
  }

  /// SHA-256 of toCanonicalJson() — convenience helper
  String get contentHash {
    final bytes = utf8.encode(jsonEncode(toCanonicalJson()));
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> _sortedMap(Map<String, dynamic> m) =>
      Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

  // ── Serialisation ──────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingId': meetingId,
    'villageId': villageId,
    'meetingDate': meetingDate,
    'geotag': geotag,
    'decisionTextEn': decisionTextEn,
    'decisionTextHi': decisionTextHi,
    'decisionTextMr': decisionTextMr,
    'sourceLanguage': sourceLanguage,
    'attendeeCount': attendeeCount,
    'registeredCount': registeredCount,
    'womenCount': womenCount,
    'quorumValid': quorumValid,
    'quorumExplanation': quorumExplanation,
    'faceMatchedCount': faceMatchedCount,
    'manualAddedCount': manualAddedCount,
    'localHash': localHash,
    'canonicalHash': canonicalHash,
    'timestampUtc': timestampUtc,
    'firestoreTimestamp': firestoreTimestamp,
    'groupPhotoLocalPath': groupPhotoLocalPath,
    'isSynced': isSynced,
  };

  factory MomRecord.fromJson(Map<String, dynamic> json) => MomRecord(
    id: json['id'] as String,
    meetingId: json['meetingId'] as String,
    villageId: json['villageId'] as String,
    meetingDate: json['meetingDate'] as String,
    geotag: json['geotag'] as String,
    decisionTextEn: json['decisionTextEn'] as String,
    decisionTextHi: json['decisionTextHi'] as String,
    decisionTextMr: json['decisionTextMr'] as String,
    sourceLanguage: json['sourceLanguage'] as String? ?? 'mr',
    attendeeCount: json['attendeeCount'] as int,
    registeredCount: json['registeredCount'] as int,
    womenCount: json['womenCount'] as int,
    quorumValid: json['quorumValid'] as bool,
    quorumExplanation: json['quorumExplanation'] as String? ?? '',
    faceMatchedCount: json['faceMatchedCount'] as int? ?? 0,
    manualAddedCount: json['manualAddedCount'] as int? ?? 0,
    localHash: json['localHash'] as String,
    canonicalHash: json['canonicalHash'] as String?,
    timestampUtc: json['timestampUtc'] as String,
    firestoreTimestamp: json['firestoreTimestamp'] as String?,
    groupPhotoLocalPath: json['groupPhotoLocalPath'] as String?,
    isSynced: json['isSynced'] as bool? ?? false,
  );

  MomRecord copyWith({
    String? canonicalHash,
    String? firestoreTimestamp,
    bool? isSynced,
    String? groupPhotoLocalPath,
  }) =>
      MomRecord(
        id: id,
        meetingId: meetingId,
        villageId: villageId,
        meetingDate: meetingDate,
        geotag: geotag,
        decisionTextEn: decisionTextEn,
        decisionTextHi: decisionTextHi,
        decisionTextMr: decisionTextMr,
        sourceLanguage: sourceLanguage,
        attendeeCount: attendeeCount,
        registeredCount: registeredCount,
        womenCount: womenCount,
        quorumValid: quorumValid,
        quorumExplanation: quorumExplanation,
        faceMatchedCount: faceMatchedCount,
        manualAddedCount: manualAddedCount,
        localHash: localHash,
        canonicalHash: canonicalHash ?? this.canonicalHash,
        timestampUtc: timestampUtc,
        firestoreTimestamp: firestoreTimestamp ?? this.firestoreTimestamp,
        groupPhotoLocalPath: groupPhotoLocalPath ?? this.groupPhotoLocalPath,
        isSynced: isSynced ?? this.isSynced,
      );
}
