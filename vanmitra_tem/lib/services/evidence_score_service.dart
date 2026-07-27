import '../core/constants/fra_constants.dart';

/// Evidence-Completeness Score service
///
/// Implements: E = (Σᵢ wᵢ·xᵢ) / (Σᵢ wᵢ), E ∈ [0, 1]
///
/// where:
///   wᵢ = weight for evidence category i (from Rule 13 calibration)
///   xᵢ = binary indicator (1 if evidence present, 0 if absent)
///
/// Source: VanMitra-AI Technical Report, Section 6.3
/// Weights calibrated against the 2024 Fact-Finding Committee case corpus,
/// where claims lacking high-weight evidence were disproportionately rejected.
class EvidenceScoreService {
  /// Calculate the Evidence-Completeness Score using the provided [weights].
  ///
  /// This is the primary method — call it with weights from [AiAgentConfig.evidenceWeights]
  /// so the Flutter score stays numerically identical to the Python ScoringAgent.
  EvidenceScoreResult calculateWithWeights(
    Map<String, bool> evidenceFlags,
    Map<String, double> weights,
  ) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    final missingItems = <String>[];

    for (final entry in weights.entries) {
      final category = entry.key;
      final weight = entry.value;

      totalWeight += weight;

      final isPresent = evidenceFlags[category] ?? false;
      if (isPresent) {
        weightedSum += weight;
      } else {
        missingItems.add(category);
      }
    }

    final score = totalWeight > 0 ? weightedSum / totalWeight : 0.0;

    EvidenceTier tier;
    String recommendation;

    if (score >= FRAConstants.greenThreshold) {
      tier = EvidenceTier.green;
      recommendation = 'Claim well-evidenced — ready for Gram Sabha review and submission.';
    } else if (score >= FRAConstants.yellowThreshold) {
      tier = EvidenceTier.yellow;
      final missingNames = missingItems.map(_categoryDisplayName).toList();
      recommendation =
          'Partial evidence — please provide: ${missingNames.join(", ")} before submission.';
    } else {
      tier = EvidenceTier.red;
      final missingNames = missingItems.map(_categoryDisplayName).toList();
      recommendation =
          'High rejection risk — collect the following evidence: ${missingNames.join(", ")}. '
          'Contact your FRC for assistance.';
    }

    return EvidenceScoreResult(
      score: score,
      tier: tier,
      missingItems: missingItems,
      missingItemNames: missingItems.map(_categoryDisplayName).toList(),
      recommendation: recommendation,
      presentCount: weights.length - missingItems.length,
      totalCount: weights.length,
    );
  }

  /// Offline fallback: calculate using the static [FRAConstants.evidenceWeights].
  /// Prefer [calculateWithWeights] when [AiAgentConfig] is loaded.
  EvidenceScoreResult calculate(Map<String, bool> evidenceFlags) {
    return calculateWithWeights(evidenceFlags, FRAConstants.evidenceWeights);
  }

  /// Get display name for an evidence category
  String _categoryDisplayName(String category) {
    switch (category) {
      case 'government_records':
        return 'Government Records (Voter ID, Ration Card, land records)';
      case 'physical_structures':
        return 'Physical Structures (wells, bunds, houses on land)';
      case 'satellite_imagery':
        return 'Satellite/Aerial Imagery';
      case 'elder_statements':
        return 'Statements of Elders (at least 2 neighbours)';
      case 'traditional_structures':
        return 'Traditional Community Structures (sacred groves, burial sites)';
      case 'other_govt_schemes':
        return 'Other Government Scheme Evidence (MGNREGA job card)';
      default:
        return category;
    }
  }

  /// Get Marathi display name for an evidence category
  static String categoryDisplayNameMr(String category) {
    switch (category) {
      case 'government_records':
        return 'शासकीय नोंदी (मतदार ओळखपत्र, रेशनकार्ड, जमीन नोंदी)';
      case 'physical_structures':
        return 'भौतिक संरचना (विहिरी, बांध, जमिनीवरील घरे)';
      case 'satellite_imagery':
        return 'उपग्रह/हवाई छायाचित्रे';
      case 'elder_statements':
        return 'वडीलधाऱ्यांचे निवेदन (किमान 2 शेजारी)';
      case 'traditional_structures':
        return 'पारंपारिक सामुदायिक संरचना (पवित्र वनखंड, दफनभूमी)';
      case 'other_govt_schemes':
        return 'इतर शासकीय योजना पुरावे (मनरेगा जॉबकार्ड)';
      default:
        return category;
    }
  }
}

/// Evidence score tier (Risk Tiering Framework)
enum EvidenceTier {
  /// E ≥ 0.8 — Claim well-evidenced
  green,

  /// 0.6 ≤ E < 0.8 — Partial evidence
  yellow,

  /// E < 0.6 — High procedural-rejection risk
  red,
}

/// Result of evidence-completeness calculation
class EvidenceScoreResult {
  final double score;
  final EvidenceTier tier;
  final List<String> missingItems; // Category keys
  final List<String> missingItemNames; // Display names
  final String recommendation;
  final int presentCount;
  final int totalCount;

  const EvidenceScoreResult({
    required this.score,
    required this.tier,
    required this.missingItems,
    required this.missingItemNames,
    required this.recommendation,
    required this.presentCount,
    required this.totalCount,
  });

  /// Score as percentage (0-100)
  double get scorePercentage => score * 100;

  /// Human-readable score
  String get displayScore => '${scorePercentage.toStringAsFixed(0)}%';

  /// Tier emoji
  String get tierEmoji {
    switch (tier) {
      case EvidenceTier.green: return '🟢';
      case EvidenceTier.yellow: return '🟡';
      case EvidenceTier.red: return '🔴';
    }
  }
}
