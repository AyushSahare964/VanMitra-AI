import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Locale provider for 4-language support
/// Persists selected language and provides Locale object for MaterialApp
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('mr')); // Default: Marathi

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
    Locale('kn'), // Konkani (using 'kn' code)
  ];

  static const Map<String, String> localeNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
    'kn': 'कोंकणी',
  };

  static const Map<String, String> localeNativeNames = {
    'en': '🇬🇧 English',
    'hi': '🇮🇳 हिंदी',
    'mr': '🏛️ मराठी',
    'kn': '🌊 कोंकणी',
  };

  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }

  String get currentLanguageName => localeNames[state.languageCode] ?? 'English';
  String get currentNativeName => localeNativeNames[state.languageCode] ?? 'English';
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
