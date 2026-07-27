import 'user_role.dart';

/// User profile in VanMitra-AI
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String villageId;
  final String? memberId; // Links to VillageMember for attendance
  final String preferredLanguage; // 'en', 'hi', 'mr', 'kn'
  final DateTime createdAt;
  final bool hasFaceEnrolled;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.villageId,
    this.memberId,
    this.preferredLanguage = 'mr',
    required this.createdAt,
    this.hasFaceEnrolled = false,
  });

  User copyWith({
    String? name,
    UserRole? role,
    String? memberId,
    String? preferredLanguage,
    bool? hasFaceEnrolled,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      villageId: villageId,
      memberId: memberId ?? this.memberId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
      hasFaceEnrolled: hasFaceEnrolled ?? this.hasFaceEnrolled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'villageId': villageId,
    'memberId': memberId,
    'preferredLanguage': preferredLanguage,
    'createdAt': createdAt.toIso8601String(),
    'hasFaceEnrolled': hasFaceEnrolled,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    role: UserRole.values.byName(json['role'] as String),
    villageId: json['villageId'] as String,
    memberId: json['memberId'] as String?,
    preferredLanguage: json['preferredLanguage'] as String? ?? 'mr',
    createdAt: DateTime.parse(json['createdAt'] as String),
    hasFaceEnrolled: json['hasFaceEnrolled'] as bool? ?? false,
  );
}
