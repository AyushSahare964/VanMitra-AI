import 'package:flutter/material.dart';
import 'app_colors.dart';

/// VanMitra-AI Typography Scale
/// Predictable typography scale across all 24 screens with Devanagari language support.
class AppTypography {
  AppTypography._();

  static const String _devanagariFamily = 'NotoSansDevanagari';

  // ── NEW STANDARD DESIGN TOKENS (6 sizes) ──────────────────────────────────
  /// 24px / 700 — Greetings, hero screen titles
  static const TextStyle display = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 18px / 600 — Section headers (e.g. "Admin Actions")
  static const TextStyle title = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// 15px / 500 — Card titles (e.g. "Schedule Meeting")
  static const TextStyle subtitle = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// 14px / 400 — Standard descriptions, form input text
  static const TextStyle body = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 12px / 400 — Metadata, timestamps, legal citations
  static const TextStyle caption = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// 28px / 700 — KPI figures ("500", "1", "14")
  static const TextStyle stat = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.forestCanopy,
    height: 1.2,
  );

  // ── LEGACY MATERIAL TEXT STYLES (Keep existing components working) ─────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineMedium = display;

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleLarge = title;

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleSmall = subtitle;
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle bodyMedium = body;
  static const TextStyle bodySmall = caption;

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _devanagariFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle hashDisplay = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle statNumber = stat;
}
