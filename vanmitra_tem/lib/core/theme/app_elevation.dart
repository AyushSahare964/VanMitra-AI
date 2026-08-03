import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Two-tier elevation system for visual hierarchy:
/// header > primary CTA > cards > list rows
enum AppElevation {
  /// No shadow, 1px subtle divider border — List rows, internal sections
  flat,

  /// Subtle lift — Standard cards, stat tiles, bottom sheets
  raised,

  /// High prominence — Floating action buttons (FAB), active modals, menus
  floating,
}

extension AppElevationExtension on AppElevation {
  List<BoxShadow>? get shadow {
    switch (this) {
      case AppElevation.flat:
        return null;
      case AppElevation.raised:
        return const [
          BoxShadow(
            color: Color(0x0F0F172A), // rgba(15,23,42,0.06)
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ];
      case AppElevation.floating:
        return const [
          BoxShadow(
            color: Color(0x1F0F172A), // rgba(15,23,42,0.12)
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ];
    }
  }

  Border? get border {
    switch (this) {
      case AppElevation.flat:
        return Border.all(color: AppColors.divider, width: 1.0);
      case AppElevation.raised:
        return Border.all(color: AppColors.divider.withValues(alpha: 0.5), width: 1.0);
      case AppElevation.floating:
        return null;
    }
  }
}
