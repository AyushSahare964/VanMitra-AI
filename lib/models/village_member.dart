/// Gender categories for quorum tracking
enum Gender { male, female, other }

/// Community category for inclusion tracking (FRA Rule 4)
enum CommunityCategory {
  /// Scheduled Tribe
  st,
  /// Particularly Vulnerable Tribal Group
  pvtg,
  /// Other Traditional Forest Dweller
  otfd,
  /// General / Other
  general,
}

/// A registered adult member of the Gram Sabha
/// Used for attendance tracking, quorum calculation, and inclusion enforcement
class VillageMember {
  final String id;
  final String nameMarathi;
  final String nameEnglish;
  final Gender gender;
  final CommunityCategory category;
  final String villageId;
  final int? age;
  final String? phoneNumber;
  final bool hasSmartphone;
  final String? faceEmbeddingId; // Reference to stored face data (legacy field, kept for compat)
  final bool isActive; // Currently a registered member

  // Module C: on-device 128-dim FaceNet embedding (null = not yet enrolled)
  final List<double>? faceEmbedding;
  // Module C: when the face was enrolled
  final DateTime? enrolledAt;

  const VillageMember({
    required this.id,
    required this.nameMarathi,
    required this.nameEnglish,
    required this.gender,
    required this.category,
    required this.villageId,
    this.age,
    this.phoneNumber,
    this.hasSmartphone = true,
    this.faceEmbeddingId,
    this.isActive = true,
    this.faceEmbedding,
    this.enrolledAt,
  });

  /// Whether this member is a woman (for W/A ≥ 1/3 quorum check)
  bool get isWoman => gender == Gender.female;

  /// Whether this member is ST (for consent resolution inclusion)
  bool get isST => category == CommunityCategory.st;

  /// Whether this member is PVTG (for consent resolution inclusion)
  bool get isPVTG => category == CommunityCategory.pvtg;

  /// Whether face is enrolled (Module C: checks actual embedding vector)
  bool get hasFaceEnrolled => faceEmbedding != null;

  VillageMember copyWith({
    String? faceEmbeddingId,
    bool? isActive,
    String? phoneNumber,
    bool? hasSmartphone,
    List<double>? faceEmbedding,
    DateTime? enrolledAt,
  }) {
    return VillageMember(
      id: id,
      nameMarathi: nameMarathi,
      nameEnglish: nameEnglish,
      gender: gender,
      category: category,
      villageId: villageId,
      age: age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hasSmartphone: hasSmartphone ?? this.hasSmartphone,
      faceEmbeddingId: faceEmbeddingId ?? this.faceEmbeddingId,
      isActive: isActive ?? this.isActive,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameMarathi': nameMarathi,
    'nameEnglish': nameEnglish,
    'gender': gender.name,
    'category': category.name,
    'villageId': villageId,
    'age': age,
    'phoneNumber': phoneNumber,
    'hasSmartphone': hasSmartphone,
    'faceEmbeddingId': faceEmbeddingId,
    'isActive': isActive,
    // Module C face enrolment fields
    'faceEmbedding': faceEmbedding,
    'enrolledAt': enrolledAt?.toIso8601String(),
  };

  factory VillageMember.fromJson(Map<String, dynamic> json) => VillageMember(
    id: json['id'] as String,
    nameMarathi: json['nameMarathi'] as String,
    nameEnglish: json['nameEnglish'] as String,
    gender: Gender.values.byName(json['gender'] as String),
    category: CommunityCategory.values.byName(json['category'] as String),
    villageId: json['villageId'] as String,
    age: json['age'] as int?,
    phoneNumber: json['phoneNumber'] as String?,
    hasSmartphone: json['hasSmartphone'] as bool? ?? true,
    faceEmbeddingId: json['faceEmbeddingId'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    // Module C face enrolment fields
    faceEmbedding: (json['faceEmbedding'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList(),
    enrolledAt: json['enrolledAt'] != null
        ? DateTime.parse(json['enrolledAt'] as String)
        : null,
  );
}
