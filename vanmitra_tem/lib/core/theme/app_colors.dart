import 'package:flutter/material.dart';

/// Maharashtra Government premium color palette for VanMitra-AI
class AppColors {
  AppColors._();

  // ── MAHA-DBT Portal Frame Design Tokens (Spec B.1) ──────────────────────
  // These match the colors used across Maharashtra government portals and the
  // MAHA-DBT portal that villagers and officials already recognize as trusted.
  static const Color govtBlue = Color(0xFF0B3D91);         // Header bar, primary buttons
  static const Color accentSaffron = Color(0xFFFF7A00);    // Active tab, New Claim CTA, notice ticker
  static const Color successGreen = Color(0xFF1E8E3E);     // Approved status, quorum met
  static const Color warningAmber = Color(0xFFF2A900);     // Partial evidence, quorum borderline
  static const Color alertRed = Color(0xFFD32F2F);         // Rejected, high-risk, encroachment

  // Branding Colors (Inspired by Indian Flag & Govt aesthetics)
  static const Color primary = Color(0xFF000080);         // Ashoka Chakra Navy Blue — distinct headers, active elements
  static const Color primaryLight = Color(0xFF333399);    // Lighter navy
  static const Color primaryDark = Color(0xFF00004D);     // Dark navy

  // Secondary — Saffron (Maharashtra / India tricolor)
  static const Color secondary = Color(0xFFFF9933);       // Saffron — CTAs, active tabs, bright accents
  static const Color secondaryLight = Color(0xFFFFB366);
  static const Color secondaryDark = Color(0xFFCC7A29);

  // Semantic colors
  static const Color success = Color(0xFF138808);         // India Green — approved, valid
  static const Color successLight = Color(0xFFE8F5E9);    
  static const Color warning = Color(0xFFF9A825);         // Amber — pending, partial
  static const Color warningLight = Color(0xFFFFF8E1);    
  static const Color error = Color(0xFFD32F2F);           // Red — rejected, invalid
  static const Color errorLight = Color(0xFFFFEBEE);      

  // Surface colors (ALL WHITE THEME)
  static const Color surface = Color(0xFFFFFFFF);         // Pure white background
  static const Color card = Color(0xFFFFFFFF);            // Pure white cards
  static const Color cardElevated = Color(0xFFFAFAFA);    // Off-white for slight elevation
  static const Color divider = Color(0xFFE2E8F0);         // Very subtle grey for borders/dividers

  // Text colors (High Contrast)
  static const Color textPrimary = Color(0xFF0F172A);     // Very dark slate (near black) for max readability
  static const Color textSecondary = Color(0xFF475569);   // Slate grey for subtitles
  static const Color textTertiary = Color(0xFF94A3B8);    // Light slate for disabled/hints
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // White on Navy
  static const Color textOnSecondary = Color(0xFFFFFFFF); // White on Saffron

  // Inclusion-specific colors
  static const Color womenQuorum = Color(0xFF7B1FA2);     // Purple
  static const Color womenQuorumLight = Color(0xFFF3E5F5);
  static const Color stRepresentation = Color(0xFF00838F); // Cyan
  static const Color stRepresentationLight = Color(0xFFE0F7FA);
  static const Color pvtgRepresentation = Color(0xFFE65100); // Orange
  static const Color pvtgRepresentationLight = Color(0xFFFBE9E7);

  // Attendance verification
  static const Color gpsVerified = Color(0xFF1976D2);
  static const Color faceVerified = Color(0xFF512DA8);
  static const Color manualEntry = Color(0xFF607D8B);
}
