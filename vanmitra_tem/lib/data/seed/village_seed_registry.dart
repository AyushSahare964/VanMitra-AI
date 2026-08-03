import '../../models/village.dart';

/// Central registry of all seeded villages in VanMitra-AI.
/// Maps canonical village IDs to their Village metadata.
/// Add new villages here so any user registration syncs their correct village document.
class VillageSeedRegistry {
  VillageSeedRegistry._();

  /// All registered seed villages, keyed by canonical ID (e.g. 'OZH-01').
  static const Map<String, Village> _seeds = {
    'OZH-01': _ozhar,
    'JWH-01': _jawhar,
    'KKD-01': _khokad,
  };

  /// Returns the seed Village for [villageId], or null if not found.
  static Village? forId(String villageId) => _seeds[villageId];

  /// All seeded village IDs.
  static Iterable<String> get allIds => _seeds.keys;

  // ─── Ozhar, Jawhar, Palghar ──────────────────────────────────────────────
  static const Village _ozhar = Village(
    id: 'OZH-01',
    nameMarathi: 'ओझर',
    nameEnglish: 'Ozhar',
    nameHindi: 'ओझर',
    talukaMarathi: 'जव्हार',
    talukaEnglish: 'Jawhar',
    districtMarathi: 'पालघर',
    districtEnglish: 'Palghar',
    stateMarathi: 'महाराष्ट्र',
    stateEnglish: 'Maharashtra',
    totalPopulation: 2100,
    registeredAdultMembers: 980,
    registeredWomenMembers: 490,
    registeredMenMembers: 490,
    stMembers: 850,
    pvtgMembers: 240,
    otfdMembers: 130,
    stPercentage: 85.0,
    pvtgPercentage: 24.0,
    latitude: 19.9167,
    longitude: 73.2667,
    meetingVenueLat: 19.9170,
    meetingVenueLng: 73.2670,
    cfrAreaHectares: 320.5,
    totalApprovedClaims: 10,
    totalApprovedAreaSqm: 120000,
    approvedRightType: 'Individual Forest Rights (IFR)',
    casteCategory: 'अनुसूचित जमाती (Scheduled Tribes - ST)',
  );

  // ─── Jawhar Town, Jawhar, Palghar ────────────────────────────────────────
  static const Village _jawhar = Village(
    id: 'JWH-01',
    nameMarathi: 'जव्हार',
    nameEnglish: 'Jawhar',
    nameHindi: 'जव्हार',
    talukaMarathi: 'जव्हार',
    talukaEnglish: 'Jawhar',
    districtMarathi: 'पालघर',
    districtEnglish: 'Palghar',
    stateMarathi: 'महाराष्ट्र',
    stateEnglish: 'Maharashtra',
    totalPopulation: 3800,
    registeredAdultMembers: 1650,
    registeredWomenMembers: 820,
    registeredMenMembers: 830,
    stMembers: 1420,
    pvtgMembers: 310,
    otfdMembers: 220,
    stPercentage: 86.1,
    pvtgPercentage: 18.8,
    latitude: 19.8981,
    longitude: 73.2218,
    meetingVenueLat: 19.8990,
    meetingVenueLng: 73.2225,
    cfrAreaHectares: 510.0,
    totalApprovedClaims: 18,
    totalApprovedAreaSqm: 215000,
    approvedRightType: 'Community Forest Rights (CFR)',
    casteCategory: 'अनुसूचित जमाती (Scheduled Tribes - ST)',
  );

  // ─── Khokad, Mokhada, Palghar ────────────────────────────────────────────
  static const Village _khokad = Village(
    id: 'KKD-01',
    nameMarathi: 'खोकड',
    nameEnglish: 'Khokad',
    nameHindi: 'खोकड',
    talukaMarathi: 'मोखाडा',
    talukaEnglish: 'Mokhada',
    districtMarathi: 'पालघर',
    districtEnglish: 'Palghar',
    stateMarathi: 'महाराष्ट्र',
    stateEnglish: 'Maharashtra',
    totalPopulation: 1450,
    registeredAdultMembers: 620,
    registeredWomenMembers: 310,
    registeredMenMembers: 310,
    stMembers: 540,
    pvtgMembers: 180,
    otfdMembers: 80,
    stPercentage: 87.1,
    pvtgPercentage: 29.0,
    latitude: 19.8431,
    longitude: 73.2993,
    meetingVenueLat: 19.8435,
    meetingVenueLng: 73.2997,
    cfrAreaHectares: 198.0,
    totalApprovedClaims: 6,
    totalApprovedAreaSqm: 72000,
    approvedRightType: 'Individual Forest Rights (IFR)',
    casteCategory: 'विशेष पिछडी जमाती (PVTG)',
  );
}
