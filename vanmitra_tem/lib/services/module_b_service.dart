import 'package:latlong2/latlong.dart';
import '../models/boundary_alert.dart';
import '../core/constants/village_constants.dart';

/// Module B Service Interface — Digital Fencing
///
/// [INTEGRATION-READY] This abstract interface defines the contract for
/// Module B's satellite-based boundary monitoring.
///
/// The [SeedModuleBService] implementation serves the 148 parcels from
/// ozar_alerts.csv (output of VanMitra_ModuleB_Ozar.ipynb, Cell 21).
/// All alerts are tagged modelVersion="demo-v1-synthetic" since the notebook
/// run used FALLBACK boundary geometry and no Earth Engine imagery.
///
/// When the GEE + Sentinel-2 pipeline is ready (see agents.py _run_analysis),
/// create a [LiveModuleBService] implementation that calls the FastAPI endpoint.
///
/// Integration endpoints:
///   POST /api/v1/satellite-monitor/run  → batch village scan
///   POST /api/v1/satellite-verify       → on-demand single parcel
///   GET  /api/v1/satellite-monitor/config
abstract class ModuleBService {
  /// Get CFR boundary polygon for a village
  Future<List<LatLng>> getCFRBoundary(String villageId);

  /// Get all boundary alerts for a village
  Future<List<BoundaryAlert>> getAlerts(String villageId);

  /// Get the satellite alert for a specific landowner (for villager-facing card)
  Future<BoundaryAlert?> getAlertForLandowner(String villageId, int landownerId);

  /// Report an alert to authorities
  Future<void> reportAlert(String alertId, String reportType);
}

/// Seed implementation — serves ozar_alerts.csv data, works fully offline.
///
/// All 148 parcels from the notebook output are embedded here so the UI
/// is functional immediately with no backend call required.
class SeedModuleBService implements ModuleBService {
  static const String _villageId = 'ozar';
  static const String _modelVersion = 'demo-v1-synthetic';

  @override
  Future<List<LatLng>> getCFRBoundary(String villageId) async {
    return VillageConstants.cfrBoundaryPolygon;
  }

  @override
  Future<List<BoundaryAlert>> getAlerts(String villageId) async {
    return _seedAlerts;
  }

  @override
  Future<BoundaryAlert?> getAlertForLandowner(String villageId, int landownerId) async {
    try {
      return _seedAlerts.firstWhere((a) => a.landownerId == landownerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> reportAlert(String alertId, String reportType) async {
    // TODO: POST to /api/v1/notices or a dedicated report endpoint
  }

  // ── Seed data (ozar_alerts.csv, 148 rows, 2026-08-04 run) ────────────────
  // tier distribution: 🔴 10 red · 🟡 7 yellow · 🟢 131 green
  // modelVersion: demo-v1-synthetic (village_boundary_source: FALLBACK,
  //               earth_engine_imagery_used: false)

  static BoundaryAlert _mk({
    required int landownerId,
    required String claimant,
    required int surveyNo,
    required double area,
    required String landUse,
    required String feasibility,
    required double areaAffected,
    required String tier,
    required String cause,
  }) {
    final alertTier = AlertTier.values.byName(tier);
    final rf = ResolutionFeasibility.values.byName(feasibility);
    return BoundaryAlert(
      id: 'ALT_${_villageId}_$landownerId',
      villageId: _villageId,
      tier: alertTier,
      detectedAt: DateTime(2026, 8, 4),
      latitude: 19.928,   // Ozar centroid — per-parcel lat/lng from EE when live
      longitude: 73.221,
      description: cause,
      landownerId: landownerId,
      claimantName: claimant,
      surveyNo: surveyNo,
      declaredAreaSqm: area,
      landUseType: landUse,
      resolutionFeasibility: rf,
      areaAffectedSqm: areaAffected,
      likelyCause: cause,
      confidence: tier == 'green' ? 0.87 : 0.72,
      ndviMean: tier == 'green' ? 0.61 : 0.15,
      modelVersion: _modelVersion,
      boundarySource: 'FALLBACK',
      imagerySource: 'synthetic',
    );
  }

  static final List<BoundaryAlert> _seedAlerts = [
    // ── Green parcels (no change) ──────────────────────────────────────────
    _mk(landownerId: 531,  claimant: 'Shevanti Bonge',               surveyNo: 463, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6985, claimant: 'Sadu Phadavale',               surveyNo: 324, area: 1100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6984, claimant: 'Ganesh Shankar Nadage',         surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6983, claimant: 'Chandar Shidaya Phadavale',     surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6982, claimant: 'Govind Suraj Bhovar',           surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6981, claimant: 'Navaji Lakshya Kadu',           surveyNo: 234, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6977, claimant: 'Motiram Padu Diva',             surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6975, claimant: 'Dilip Lahanu Kharapade',        surveyNo: 324, area: 600,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6973, claimant: 'Brakshman Janu Bonge',          surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6972, claimant: 'Govaji Ghakal Phadavale',       surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6971, claimant: 'Navaji Phadavale',              surveyNo: 324, area: 7000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6906, claimant: 'Vishnu Nadage',                 surveyNo: 324, area: 4500,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6799, claimant: 'Vasant Bachchu Phadavale',      surveyNo: 324, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6791, claimant: 'Dasama Shravan Bonge',          surveyNo: 324, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6782, claimant: 'Dhanaji Dival Diva',            surveyNo: 324, area: 9400,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6986, claimant: 'Lakshman Lahanu Phadavale',     surveyNo: 324, area: 12900, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6775, claimant: 'Babu Nathu Nibara',             surveyNo: 317, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6765, claimant: 'Saguni Khanajhode',             surveyNo: 324, area: 8100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6763, claimant: 'Shankar Kakadaya Phadavale',    surveyNo: 324, area: 600,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6760, claimant: 'Sonak Gadage',                  surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6759, claimant: 'Yashavant Navasha Gharat',      surveyNo: 324, area: 3000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6749, claimant: 'Mahadu Janu Garel',             surveyNo: 316, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6735, claimant: 'Shakar Savanji Diva',           surveyNo: 324, area: 5700,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6717, claimant: 'Chandu Chaitya Diva',           surveyNo: 324, area: 200,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6706, claimant: 'Manji Janya Bonge',             surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6703, claimant: 'Ramaji Santya Nadage',          surveyNo: 316, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6701, claimant: 'Riti Lahu Diva',                surveyNo: 316, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6173, claimant: 'Lahu Devaram Diva',             surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7522, claimant: 'Suresh Phadavale',              surveyNo: 324, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6169, claimant: 'Devaram Janya Boge',            surveyNo: 317, area: 200,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6168, claimant: 'Jau Phadavale',                 surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6770, claimant: 'Rahi Kisan Gurav',              surveyNo: 324, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6987, claimant: 'Yashavant Bachchu Phadavale',   surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6988, claimant: 'Tulashi Raghya Kavad',          surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6990, claimant: 'Devaji Rupaji Kharapade',       surveyNo: 324, area: 9100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7520, claimant: 'Vishnu Boge',                   surveyNo: 324, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7517, claimant: 'Mavanji Phadavale',             surveyNo: 324, area: 200,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7293, claimant: 'Ramesh Chandar Kavad',          surveyNo: 326, area: 600,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7289, claimant: 'Andesh Jamana Bangad',          surveyNo: 324, area: 200,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7260, claimant: 'Raju Jatrya Bhavar',            surveyNo: 316, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7088, claimant: 'Suresh Lahanu Kharapade',       surveyNo: 324, area: 1200,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7086, claimant: 'Chandu Santya Jabar',           surveyNo: 324, area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7084, claimant: 'Sandip Lahanu Kharapade',       surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7052, claimant: 'Lahanya Lakhama Phadavale',     surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7051, claimant: 'Ladakya Dhavaji Kadu',          surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7019, claimant: 'Amrit Phadavale',               surveyNo: 324, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7018, claimant: 'Kashinath Raghya Kavad',        surveyNo: 324, area: 100,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7017, claimant: 'Ratan Phadavale',               surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7016, claimant: 'Nathu Ratan Gurav',             surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7015, claimant: 'Ratilal Devaram Bonge',         surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7013, claimant: 'Madhu Diva',                    surveyNo: 314, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7012, claimant: 'Ambya Mangalaya Bhoye',         surveyNo: 324, area: 5100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6992, claimant: 'Suvana Lakshman Phadavale',     surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6993, claimant: 'Brakshman Lahanu Kharapade',    surveyNo: 324, area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6994, claimant: 'Baban Deu Dhanagar',            surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6996, claimant: 'Rapaji Kharapade',              surveyNo: 324, area: 300,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6997, claimant: 'Anaji Kharapade',               surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6998, claimant: 'Babulal Kareka',                surveyNo: 324, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6167, claimant: 'Sunil Kakadaya Kavad',          surveyNo: 324, area: 100,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6999, claimant: 'Ramachandr Phadavale',          surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7001, claimant: 'Vinayak Phadake',               surveyNo: 324, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7005, claimant: 'Mun Lakshman Kadu',             surveyNo: 324, area: 7800,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7006, claimant: 'Ramani Babaji Diva',            surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7008, claimant: 'Govid Bachyu Nadage',           surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7009, claimant: 'Bachyu Ladakya Nadage',         surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7010, claimant: 'Keshav Kadu',                   surveyNo: 324, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7000, claimant: 'Dasama Bonge',                  surveyNo: 324, area: 700,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6166, claimant: 'Babalya Shankar Murad',         surveyNo: 324, area: 200,   landUse: 'Domestic/Homestead',   feasibility: 'unreliable', areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6170, claimant: 'Shakar Damu Phadavale',         surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6164, claimant: 'Shankar Kakadaya Diva',         surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1984, claimant: 'Bhagi Janu Diva',               surveyNo: 324, area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1986, claimant: 'Sonya Dhakal Rajad',            surveyNo: 324, area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2112, claimant: 'Raghu Digha',                   surveyNo: 336, area: 3500,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2140, claimant: 'Shanti Nadage',                 surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2142, claimant: 'Chandar Soma Dambare',          surveyNo: 324, area: 9300,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2288, claimant: 'Tulashi Diva',                  surveyNo: 324, area: 5500,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1935, claimant: 'Tulaje Rama Diva',              surveyNo: 324, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2777, claimant: 'Kisan Garel',                   surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2779, claimant: 'Shantaram Diva',                surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2780, claimant: 'Shantaram Dharma Katela',       surveyNo: 324, area: 13000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2781, claimant: 'Ramadas Bendu Nadage',          surveyNo: 324, area: 13000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2788, claimant: 'Ramaji Lakshman Vangad',        surveyNo: 324, area: 7000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2789, claimant: 'Jamana Ramaji Diva',            surveyNo: 324, area: 6000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6165, claimant: 'Ladak Devu Digha',              surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2778, claimant: 'Kashiram Deu Diva',             surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2791, claimant: 'Savaji Deu Valavi',             surveyNo: 324, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1924, claimant: 'Pandu Dharma Diva',             surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1843, claimant: 'Bachchu Janu Diva',             surveyNo: 324, area: 16000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1191, claimant: 'Devaje Ragho Deva',             surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1266, claimant: 'Deu Lakshya Phadavale',         surveyNo: 224, area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1268, claimant: 'Chunilal Bachu Phadavale',      surveyNo: 324, area: 14000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1318, claimant: 'Ashok Dhavalu Bhoye',           surveyNo: 327, area: 6000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1339, claimant: 'Shankar Kakadaya Khanajhode',   surveyNo: 324, area: 4500,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1374, claimant: 'Pavani Bonge',                  surveyNo: 324, area: 9000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1895, claimant: 'Gopya Mohanya Diva',            surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1380, claimant: 'Nasu Gurav',                    surveyNo: 324, area: 11500, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1407, claimant: 'Ramesh Ragho Diva',             surveyNo: 324, area: 9000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1439, claimant: 'Kashiram Ladakya Tembare',      surveyNo: 324, area: 9000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1447, claimant: 'Bachchu Bhiva Phadavale',       surveyNo: 324, area: 13000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1645, claimant: 'Janya Navasha Digha',           surveyNo: 14,  area: 8000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1731, claimant: 'Kakad Vangad',                  surveyNo: 328, area: 11000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1817, claimant: 'Santa Shankar Gurav',           surveyNo: 324, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 1397, claimant: 'Chitaman Bhovar',               surveyNo: 324, area: 13000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2792, claimant: 'Kisan Janya Diva',              surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2790, claimant: 'Santya Raghya Kavad',           surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2794, claimant: 'Dhakal Ragho Digha',            surveyNo: 324, area: 4530,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6145, claimant: 'Ramesh Bachchu Phadavale',      surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6128, claimant: 'Kisan Ramaji Diva',             surveyNo: 316, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6116, claimant: 'Bandu Ramu Vahut',              surveyNo: 316, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6112, claimant: 'Chandar Ratan Bhovar',          surveyNo: 316, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6088, claimant: 'Santa Shankar Gurav',           surveyNo: 316, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6084, claimant: 'Balakrishn Manvaji Phadavale',  surveyNo: 316, area: 1500,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 6074, claimant: 'Lakhama Devu Diva',             surveyNo: 316, area: 600,   landUse: 'Domestic/Homestead',   feasibility: 'marginal',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 5938, claimant: 'Balu Lahanu Tabare',            surveyNo: 316, area: 3000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 5935, claimant: 'Mohan Balu Phadavale',          surveyNo: 324, area: 2000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 5879, claimant: 'Baban Gopal Sapata',            surveyNo: 324, area: 2200,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 5761, claimant: 'Krishna Ganapat Boge',          surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 5748, claimant: 'Devaji Ravate',                 surveyNo: 324, area: 1000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2793, claimant: 'Vasant Diva',                   surveyNo: 324, area: 7000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 3848, claimant: 'Tukaram Santya Diva',           surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 3694, claimant: 'Ladakya Boge',                  surveyNo: 324, area: 6600,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 7578, claimant: 'Ramadas Indya Phadavale',       surveyNo: 324, area: 4000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 3686, claimant: 'Sakharam Raghu Kadu',           surveyNo: 324, area: 16000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2795, claimant: 'Changuna Diva',                 surveyNo: 324, area: 7200,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2797, claimant: 'Kama Ranjad',                   surveyNo: 324, area: 10000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2800, claimant: 'Shevati Vangad',                surveyNo: 326, area: 14000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2801, claimant: 'Lahanu Rupaji Kharapade',       surveyNo: 324, area: 27000, landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 3356, claimant: 'Babalya Gavate',                surveyNo: 316, area: 2600,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 2799, claimant: 'Babulal Guna Diva',             surveyNo: 324, area: 7300,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),
    _mk(landownerId: 3681, claimant: 'Sonya Radhya Kavad',            surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable',   areaAffected: 0,      tier: 'green',  cause: 'No change detected'),

    // ── Red parcels (🔴 Illegal Clearing / Logging) ───────────────────────
    _mk(landownerId: 6744, claimant: 'Navasha Kakadaya Phadavale',   surveyNo: 324, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 4900,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 3710, claimant: 'Dama Janya Diva',               surveyNo: 316, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 4900,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 2796, claimant: 'Chandar Lrahanu Varatha',       surveyNo: 324, area: 6700,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 6400,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6172, claimant: 'Abu Diva',                      surveyNo: 324, area: 2300,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 2500,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 7087, claimant: 'Sangita Vasant Bambere',        surveyNo: 324, area: 900,   landUse: 'Domestic/Homestead',   feasibility: 'reliable', areaAffected: 900,    tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6989, claimant: 'Mohan Phadavale',               surveyNo: 324, area: 9100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 10000,  tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 3693, claimant: 'Janya Lakshya Phadavale',       surveyNo: 324, area: 5100,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 4900,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 3643, claimant: 'Dasama Nadage',                 surveyNo: 317, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 4900,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 3442, claimant: 'Shalu Deu Rade',                surveyNo: 316, area: 5000,  landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 4900,   tier: 'red',    cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6976, claimant: 'Lakshya Rupa Vangad',           surveyNo: 324, area: 20000, landUse: 'Agricultural/Farmland', feasibility: 'reliable', areaAffected: 19600,  tier: 'red',    cause: 'Illegal Clearing / Logging'),

    // ── Yellow parcels (🟡 Possible change / marginal feasibility) ────────
    _mk(landownerId: 7085, claimant: 'Govind Ravaji Phadavale',      surveyNo: 324, area: 600,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 400,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6970, claimant: 'Lahu Diva',                    surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 900,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 2157, claimant: 'Ramaji Lal Kadu',              surveyNo: 316, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 400,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6726, claimant: 'Lakhama Diva',                 surveyNo: 316, area: 400,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 400,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 6132, claimant: 'Manji Gondaya Vagh',           surveyNo: 317, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 400,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 1016, claimant: 'Sitaram Devaji Diva',          surveyNo: 316, area: 500,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 400,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
    _mk(landownerId: 7011, claimant: 'Chandraya Laksha Kadu',        surveyNo: 324, area: 800,   landUse: 'Domestic/Homestead',   feasibility: 'marginal', areaAffected: 900,    tier: 'yellow', cause: 'Illegal Clearing / Logging'),
  ];
}

/// Convenience alias — existing code that used DefaultModuleBService will
/// automatically use the seed data implementation.
typedef DefaultModuleBService = SeedModuleBService;
