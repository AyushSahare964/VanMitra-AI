/// Forest Rights Act (FRA) 2006 legal constants and thresholds
/// All values derived from FRA Act, FRA Rules 2008/2012, PESA 1996, FCA 1980
///
/// References:
///   - FRA 2006: Sections 3, 4, 6
///   - FRA Rules 2008: Rules 4, 13
///   - 2009 MoEFCC Circular: Gram Sabha consent for forest diversion
///   - PESA 1996: Fifth Schedule Gram Sabha powers
class FRAConstants {
  FRAConstants._();

  // ──────────────────────────────────────────────────────
  // RULE 4 — GRAM SABHA QUORUM THRESHOLDS
  // ──────────────────────────────────────────────────────

  /// Minimum attendance ratio: A/R ≥ 0.5 (50% of registered adult members)
  /// Source: FRA Rules 2008, Rule 4
  static const double minAttendanceRatio = 0.50;

  /// Minimum women's attendance ratio: W/A ≥ 1/3 (33.33% of attendees must be women)
  /// Source: FRA Rules 2008, Rule 4 read with FRA Sec. 2(g)
  static const double minWomenRatio = 1.0 / 3.0;

  /// For consent resolutions (forest diversion under FCA 1980):
  /// Enhanced requirements per 2009 MoEFCC Circular
  static const double consentMinAttendanceRatio = 0.50;
  static const bool consentRequiresSTRepresentation = true;
  static const bool consentRequiresPVTGPresence = true;

  // ──────────────────────────────────────────────────────
  // SECTION 6 — APPEAL PROVISIONS
  // ──────────────────────────────────────────────────────

  /// Days allowed to file appeal after rejection
  /// Source: FRA 2006, Section 6
  static const int appealWindowDays = 60;

  /// Appeal hierarchy: SDLC → DLC
  static const String appealLevel1 = 'Sub-Divisional Level Committee (SDLC)';
  static const String appealLevel2 = 'District Level Committee (DLC)';

  // ──────────────────────────────────────────────────────
  // RULE 13 — EVIDENCE CATEGORIES & WEIGHTS
  // ──────────────────────────────────────────────────────

  /// Evidence category weights for Evidence-Completeness Score
  /// E = (Σᵢ wᵢ·xᵢ) / (Σᵢ wᵢ), E ∈ [0, 1]
  ///
  /// NOTE: These static values are the offline fallback only.
  /// At runtime the app reads from [AiAgentConfig.evidenceWeights] (loaded from
  /// assets/ai_config/evidence_weights.json) to stay numerically identical
  /// to the Python ScoringAgent.EVIDENCE_WEIGHTS in the notebook/backend.
  ///
  /// Key names match the bundle canonical keys exactly (DO NOT rename):
  ///   physical_structures (not physical_attestation).
  static const Map<String, double> evidenceWeights = {
    'government_records': 0.25,      // Voter ID, ration card, land records, court records
    'physical_structures': 0.25,     // Wells, bunds, houses, permanent improvements
    'satellite_imagery': 0.15,       // Historical imagery showing occupation/cultivation
    'elder_statements': 0.15,        // Sworn statements from ≥2 elder neighbours
    'traditional_structures': 0.10,  // Sacred groves, burial sites, customary markers
    'other_govt_schemes': 0.10,      // MGNREGA job cards, ration allocations
  };

  /// Evidence-Completeness Score thresholds (Risk Tiering Framework)
  /// Source: VanMitra-AI Technical Report Sec. 14.1
  static const double greenThreshold = 0.80;  // E ≥ 0.8 → well-evidenced
  static const double yellowThreshold = 0.60; // 0.6 ≤ E < 0.8 → partial evidence
  // E < 0.6 → high procedural-rejection risk (Red)

  // ──────────────────────────────────────────────────────
  // SECTION 3 — THREE RIGHTS UNDER FRA
  // ──────────────────────────────────────────────────────

  /// Individual Forest Right — Sec. 3(1)(a)
  static const String ifrSection = 'Section 3(1)(a)';
  static const String ifrDescription =
      'Right to live and cultivate forest land without eviction, '
      'for occupation before 13.12.2005';

  /// Community Right — Sec. 3(1)(b-d)
  static const String crSection = 'Section 3(1)(b-d)';
  static const String crDescription =
      'Right to collect, use and dispose of Minor Forest Produce (MFP), '
      'grazing, and access rights';

  /// Community Forest Resource Right — Sec. 3(1)(i)
  static const String cfrrSection = 'Section 3(1)(i)';
  static const String cfrrDescription =
      'Right of the Gram Sabha to protect, regenerate, conserve '
      'and manage community forest resources';

  // ──────────────────────────────────────────────────────
  // KEY DATES
  // ──────────────────────────────────────────────────────

  /// Occupation cutoff date for IFR claims
  /// Source: FRA 2006, Sec. 4(3)
  static const String occupationCutoffDate = '2005-12-13';

  /// FRA enacted date
  static const String fraEnactedDate = '2006-12-29';

  /// FRA Rules notified date
  static const String fraRulesDate = '2008-01-01';

  // ──────────────────────────────────────────────────────
  // FORMS
  // ──────────────────────────────────────────────────────

  /// Form A: Individual Forest Right / Community Right claim
  static const String formAName = 'Form A';
  static const String formADescription =
      'Claim form for Individual Forest Rights (IFR) under Sec. 3(1)(a) '
      'or Community Rights (CR) under Sec. 3(1)(b-d)';

  /// Form B: Community Forest Resource Right claim
  static const String formBName = 'Form B';
  static const String formBDescription =
      'Claim form for Community Forest Resource Rights (CFRR) '
      'under Sec. 3(1)(i)';

  // ──────────────────────────────────────────────────────
  // GPS GEOFENCING FOR ATTENDANCE
  // ──────────────────────────────────────────────────────

  /// Radius in meters for GPS attendance verification
  static const double geofenceRadiusMeters = 100.0;

  /// Minimum GPS accuracy required (meters)
  static const double minGpsAccuracyMeters = 50.0;

  // ──────────────────────────────────────────────────────
  // FACE RECOGNITION
  // ──────────────────────────────────────────────────────

  /// Minimum confidence threshold for face match
  static const double faceMatchThreshold = 0.85;

  /// Number of face captures during enrollment
  static const int faceEnrollmentCaptures = 3;

  // ──────────────────────────────────────────────────────
  // HASH CHAIN
  // ──────────────────────────────────────────────────────

  /// Genesis block prefix for a village ledger
  static const String genesisPrefix = 'VANMITRA_GENESIS';

  /// Hash algorithm
  static const String hashAlgorithm = 'SHA-256';
}
