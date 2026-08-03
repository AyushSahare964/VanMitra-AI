import 'package:flutter/material.dart';

/// Unified VanMitra-AI Design Tokens
/// Organizes colors by functional role, establishing Forest Green (forestCanopy)
/// as the brand primary paired with Saffron accents and high-contrast surfaces.
class AppColors {
  AppColors._();

  // ── 1. Brand Tokens ────────────────────────────────────────────────────────
  /// Brand primary: Header, bottom nav base, primary surfaces — dominant app identity
  static const Color forestCanopy = Color(0xFF1B4332);
  
  /// Brand mid: Gradients (hero cards), secondary buttons, active states
  static const Color forestSage = Color(0xFF2D6A4F);
  
  /// Brand tint: Light background tints, badge fills, onboarding accents
  static const Color forestMist = Color(0xFF95D5B2);

  /// Brand accent: High-energy call-to-actions, active tab indicator, ticker bar
  static const Color saffron = Color(0xFFFF7A00);

  /// Institutional accent (demoted): Legal Rights Hub, official document stamps
  static const Color govtBlue = Color(0xFF0B3D91);

  // ── 2. Semantic & Status Tokens ─────────────────────────────────────────────
  /// Approved status, valid quorum met (warmer & brighter than forestCanopy)
  static const Color successGreen = Color(0xFF2E7D32);
  
  /// Pending verification, partial evidence, borderline quorum warnings
  static const Color warningAmber = Color(0xFFF2A900);
  
  /// Rejected claims, severe satellite alerts, hash chain tampering detected
  static const Color alertRed = Color(0xFFD32F2F);

  // ── 3. Demographic & Biometrics ─────────────────────────────────────────────
  static const Color womenPurple = Color(0xFF7B1FA2);    // Rule 4 Women quorum tracking (33%+)
  static const Color stCyan = Color(0xFF00838F);         // Scheduled Tribe representation
  static const Color pvtgOrange = Color(0xFFE65100);     // PVTG representation flags
  static const Color faceDeepPurple = Color(0xFF512DA8); // Biometric facial liveness stamp
  static const Color gpsBlue = Color(0xFF1976D2);        // Geofence verified location badge

  // ── 4. Surfaces & Neutral Hierarchy ─────────────────────────────────────────
  /// Screen background — faint green-gray providing rich visual depth behind white cards
  static const Color surfaceBase = Color(0xFFF4F7F5);
  
  /// Standard card / sheet surface — pure white for sunlight legibility
  static const Color surfaceCard = Color(0xFFFFFFFF);
  
  /// Stat tile backgrounds & input backgrounds — faint forest tint
  static const Color surfaceSunken = Color(0xFFEAF2ED);
  
  /// Borders, section splitters, gridlines
  static const Color divider = Color(0xFFDCE7E1);

  // ── 5. Typography Colors (High Contrast) ───────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);    // Near-black slate for maximum legibility
  static const Color textSecondary = Color(0xFF475569);  // Mid-slate for metadata & timestamps
  static const Color textTertiary = Color(0xFF94A3B8);   // Light slate for disabled/hints
  static const Color textOnBrand = Color(0xFFFFFFFF);    // White over Forest Canopy / Saffron

  // ── 6. Legacy / Compatibility Mappings (Ensure zero breakage during renovation) ─
  static const Color primary = forestCanopy;
  static const Color primaryLight = forestSage;
  static const Color primaryDark = Color(0xFF0F241A);

  static const Color secondary = saffron;
  static const Color secondaryLight = Color(0xFFFF9E3D);
  static const Color secondaryDark = Color(0xFFCC5B00);

  static const Color accentSaffron = saffron;

  static const Color success = successGreen;
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = warningAmber;
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = alertRed;
  static const Color errorLight = Color(0xFFFFEBEE);

  static const Color surface = surfaceBase;
  static const Color card = surfaceCard;
  static const Color cardElevated = surfaceSunken;
  
  static const Color textOnPrimary = textOnBrand;
  static const Color textOnSecondary = textOnBrand;

  static const Color womenQuorum = womenPurple;
  static const Color womenQuorumLight = Color(0xFFF3E5F5);
  static const Color stRepresentation = stCyan;
  static const Color stRepresentationLight = Color(0xFFE0F7FA);
  static const Color pvtgRepresentation = pvtgOrange;
  static const Color pvtgRepresentationLight = Color(0xFFFBE9E7);

  static const Color gpsVerified = gpsBlue;
  static const Color faceVerified = faceDeepPurple;
  static const Color manualEntry = Color(0xFF607D8B);
}
