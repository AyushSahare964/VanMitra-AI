/// Module C — Resolution (spoken/written decision recorded at a Gram Sabha)
///
/// Wraps the raw STT transcript and its trilingual translations.
/// Must be reviewed by the Secretary ([isUserReviewed] = true) before
/// being incorporated into a [MomRecord] — AI output is never auto-finalized.
class ResolutionModel {
  final String id;
  final String meetingId;
  final String villageId;

  /// Local file path of the recorded audio (null if text was entered manually)
  final String? audioFilePath;

  /// Language of the original spoken input
  /// 'mr' = Marathi, 'hi' = Hindi, 'gon' = Gondi, 'wbr' = Warli
  final String sourceLanguage;

  /// Raw output from speech_to_text — editable by the Secretary before MoM assembly
  final String rawTranscript;

  // ── Trilingual text (populated by OnDeviceTranslationService) ─────────────
  /// English translation (mr→en via ML Kit)
  final String textEn;

  /// Hindi translation (en→hi via ML Kit)
  final String textHi;

  /// Marathi text (source if mr, or translated from hi/en)
  final String textMr;

  /// Always true for STT output and ML Kit translations — drives the amber review banner
  final bool isAiGenerated;

  /// The Secretary must explicitly confirm each tab before MoM assembly proceeds.
  /// Blocks [MomAssemblyService.assembleMom] until this is true.
  final bool isUserReviewed;

  final DateTime createdAt;

  const ResolutionModel({
    required this.id,
    required this.meetingId,
    required this.villageId,
    required this.sourceLanguage,
    required this.rawTranscript,
    required this.textEn,
    required this.textHi,
    required this.textMr,
    required this.createdAt,
    this.audioFilePath,
    this.isAiGenerated = true,
    this.isUserReviewed = false,
  });

  ResolutionModel copyWith({
    String? rawTranscript,
    String? textEn,
    String? textHi,
    String? textMr,
    bool? isUserReviewed,
  }) =>
      ResolutionModel(
        id: id,
        meetingId: meetingId,
        villageId: villageId,
        sourceLanguage: sourceLanguage,
        rawTranscript: rawTranscript ?? this.rawTranscript,
        textEn: textEn ?? this.textEn,
        textHi: textHi ?? this.textHi,
        textMr: textMr ?? this.textMr,
        createdAt: createdAt,
        audioFilePath: audioFilePath,
        isAiGenerated: isAiGenerated,
        isUserReviewed: isUserReviewed ?? this.isUserReviewed,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingId': meetingId,
    'villageId': villageId,
    'audioFilePath': audioFilePath,
    'sourceLanguage': sourceLanguage,
    'rawTranscript': rawTranscript,
    'textEn': textEn,
    'textHi': textHi,
    'textMr': textMr,
    'isAiGenerated': isAiGenerated,
    'isUserReviewed': isUserReviewed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ResolutionModel.fromJson(Map<String, dynamic> json) => ResolutionModel(
    id: json['id'] as String,
    meetingId: json['meetingId'] as String,
    villageId: json['villageId'] as String,
    audioFilePath: json['audioFilePath'] as String?,
    sourceLanguage: json['sourceLanguage'] as String? ?? 'mr',
    rawTranscript: json['rawTranscript'] as String,
    textEn: json['textEn'] as String,
    textHi: json['textHi'] as String,
    textMr: json['textMr'] as String,
    isAiGenerated: json['isAiGenerated'] as bool? ?? true,
    isUserReviewed: json['isUserReviewed'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
