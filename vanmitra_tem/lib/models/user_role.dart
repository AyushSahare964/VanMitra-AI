/// User roles in VanMitra-AI
enum UserRole {
  /// Gram Sabha Admin — can manage meetings, attendance, resolutions, review claims
  admin,

  /// Villager / Claimant — can file claims, mark self-attendance, view records
  villager,
}

/// Extension for display names
extension UserRoleExtension on UserRole {
  String get displayNameEn {
    switch (this) {
      case UserRole.admin:
        return 'Gram Sabha Admin';
      case UserRole.villager:
        return 'Villager / Claimant';
    }
  }

  String get displayNameMr {
    switch (this) {
      case UserRole.admin:
        return 'ग्रामसभा प्रशासक';
      case UserRole.villager:
        return 'ग्रामस्थ / दावेदार';
    }
  }

  String get descriptionEn {
    switch (this) {
      case UserRole.admin:
        return 'Manage meetings, review claims, monitor boundaries';
      case UserRole.villager:
        return 'File claims, attend meetings, view village records';
    }
  }
}
