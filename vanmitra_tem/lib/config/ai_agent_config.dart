import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typed loader for the VanMitra Model A bundle's agent_configs/*.json files.
///
/// Ensures the Flutter app, the Colab notebook, and the FastAPI backend use
/// numerically identical constants (evidence weights, eligibility dates, etc.)
/// by reading from the same source-of-truth JSON files rather than hardcoding.
///
/// Per the spec, this is loaded once at startup via [aiAgentConfigProvider]
/// and consumed by [EvidenceScoreService] and the claims workflow screens.
class AiAgentConfig {
  /// Six evidence category weights (from evidence_weights.json).
  /// Keys match the Python ScoringAgent.EVIDENCE_WEIGHTS exactly:
  ///   government_records, physical_structures, satellite_imagery,
  ///   elder_statements, traditional_structures, other_govt_schemes
  final Map<String, double> evidenceWeights;

  /// Rejection reason class list (from rejection_classes.json).
  final List<String> rejectionClasses;

  /// Rejection keyword map per class (from rejection_classes.json).
  final Map<String, List<String>> rejectionKeywords;

  /// Form titles per form type and language (from form_titles.json).
  /// Structure: { "A": { "mr": "...", "en": "..." }, "B": {...}, "C": {...} }
  final Map<String, Map<String, String>> formTitles;

  /// FDST/OTFD occupation cutoff date (2005-12-13) from eligibility_rules.json.
  final DateTime fdstOtfdCutoffDate;

  /// Minimum years of forest dependence for OTFD category (75).
  final int otfdMinYearsOfDependence;

  /// A human-readable note from the eligibility_rules.json.
  final String eligibilityNote;

  /// Bundle version key (if present) — used to detect client/server drift.
  final String? bundleVersion;

  const AiAgentConfig._({
    required this.evidenceWeights,
    required this.rejectionClasses,
    required this.rejectionKeywords,
    required this.formTitles,
    required this.fdstOtfdCutoffDate,
    required this.otfdMinYearsOfDependence,
    required this.eligibilityNote,
    this.bundleVersion,
  });

  /// Load all 4 agent_config JSON files from Flutter assets.
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized()].
  /// Throw on any missing or malformed file so mismatches fail fast.
  static Future<AiAgentConfig> load() async {
    // evidence_weights.json — { "government_records": 0.25, ... }
    final weightsRaw = jsonDecode(
      await rootBundle.loadString('assets/ai_config/evidence_weights.json'),
    ) as Map<String, dynamic>;

    // rejection_classes.json — { "classes": [...], "keywords": { cls: [kw, ...] } }
    final rejectionRaw = jsonDecode(
      await rootBundle.loadString('assets/ai_config/rejection_classes.json'),
    ) as Map<String, dynamic>;

    // form_titles.json — { "A": { "mr": "...", "en": "..." }, ... }
    final titlesRaw = jsonDecode(
      await rootBundle.loadString('assets/ai_config/form_titles.json'),
    ) as Map<String, dynamic>;

    // eligibility_rules.json — { "fdst_otfd_cutoff_date": "2005-12-13", ... }
    final eligibilityRaw = jsonDecode(
      await rootBundle.loadString('assets/ai_config/eligibility_rules.json'),
    ) as Map<String, dynamic>;

    // Parse evidence weights
    final evidenceWeights = weightsRaw.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    // Parse rejection classes + keywords
    final rejectionClasses = List<String>.from(rejectionRaw['classes'] as List);
    final keywordsRaw = (rejectionRaw['keywords'] as Map<String, dynamic>?) ?? {};
    final rejectionKeywords = keywordsRaw.map(
      (cls, kwList) => MapEntry(cls, List<String>.from(kwList as List)),
    );

    // Parse form titles
    final formTitles = titlesRaw.map(
      (formType, langMap) => MapEntry(
        formType,
        Map<String, String>.from(langMap as Map),
      ),
    );

    // Parse eligibility rules
    final cutoffDate = DateTime.parse(
      eligibilityRaw['fdst_otfd_cutoff_date'] as String,
    );
    final minYears =
        (eligibilityRaw['otfd_minimum_years_of_dependence'] as int?) ?? 75;
    final note = (eligibilityRaw['note'] as String?) ?? '';
    final version = eligibilityRaw['bundle_version'] as String?;

    return AiAgentConfig._(
      evidenceWeights: evidenceWeights,
      rejectionClasses: rejectionClasses,
      rejectionKeywords: rejectionKeywords,
      formTitles: formTitles,
      fdstOtfdCutoffDate: cutoffDate,
      otfdMinYearsOfDependence: minYears,
      eligibilityNote: note,
      bundleVersion: version,
    );
  }

  /// Returns the form title for [formType] (A/B/C) in [language] (mr/en/hi/kn).
  /// Falls back to English if the requested language is not available.
  String getFormTitle(String formType, String language) {
    final titles = formTitles[formType];
    if (titles == null) return 'Form $formType';
    return titles[language] ?? titles['en'] ?? 'Form $formType';
  }

  /// Total weight sum (should always be 1.0 if weights are properly normalized).
  double get totalWeight =>
      evidenceWeights.values.fold(0.0, (a, b) => a + b);
}

/// Riverpod provider — loaded once at startup, cached for the app lifetime.
/// Screens read this with [ref.watch(aiAgentConfigProvider)] and handle
/// the AsyncValue loading/error states gracefully.
final aiAgentConfigProvider = FutureProvider<AiAgentConfig>(
  (ref) => AiAgentConfig.load(),
);
