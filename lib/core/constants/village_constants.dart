import 'package:latlong2/latlong.dart';

/// Real village data for ओझर (Ozhar), Jawhar Taluka, Palghar District
/// Population estimates based on typical Jawhar taluka tribal village demographics
class VillageConstants {
  VillageConstants._();

  // ──────────────────────────────────────────────────────
  // VILLAGE IDENTITY
  // ──────────────────────────────────────────────────────

  static const String villageName = 'ओझर';
  static const String villageNameEn = 'Ozhar';
  static const String villageNameHi = 'ओझर';
  static const String villageNameKn = 'ओझर';

  static const String talukaName = 'जव्हार';
  static const String talukaNameEn = 'Jawhar';

  static const String districtName = 'पालघर';
  static const String districtNameEn = 'Palghar';

  static const String stateName = 'महाराष्ट्र';
  static const String stateNameEn = 'Maharashtra';

  // ──────────────────────────────────────────────────────
  // DEMOGRAPHICS (Approximate — typical Jawhar taluka village)
  // ──────────────────────────────────────────────────────

  /// Total village population
  static const int totalPopulation = 1200;

  /// Registered adult members (eligible for Gram Sabha)
  /// ~42% of total population (adults >18 years)
  static const int registeredAdultMembers = 500;

  /// Women among registered members (~50% of adults)
  static const int registeredWomenMembers = 250;

  /// Men among registered members
  static const int registeredMenMembers = 250;

  /// Scheduled Tribe (ST) percentage — Jawhar taluka is predominantly tribal
  static const double stPercentage = 0.85;
  static const int stMembers = 425; // 85% of 500

  /// Particularly Vulnerable Tribal Group (PVTG) — Katkari tribe in Palghar
  static const double pvtgPercentage = 0.05;
  static const int pvtgMembers = 25; // 5% of 500

  /// Other Traditional Forest Dwellers (OTFD)
  static const int otfdMembers = 50; // 10% of 500

  // ──────────────────────────────────────────────────────
  // GEOGRAPHY
  // ──────────────────────────────────────────────────────

  /// Village center coordinates (Jawhar taluka, Palghar district)
  static const double latitude = 19.7800;
  static const double longitude = 73.2200;

  /// Gram Sabha meeting venue (village center / panchayat office)
  static const double meetingVenueLat = 19.7800;
  static const double meetingVenueLng = 73.2200;

  /// Approximate CFR boundary area
  static const double cfrAreaHectares = 500.0;
  static const double cfrAreaSqMeters = 5000000.0;

  /// CFR boundary polygon (approximate — Jawhar taluka forest zone)
  /// These coordinates define a polygon around the Ozhar village forest area
  static List<LatLng> get cfrBoundaryPolygon => const [
    LatLng(19.7950, 73.2050),
    LatLng(19.7970, 73.2150),
    LatLng(19.7920, 73.2300),
    LatLng(19.7850, 73.2350),
    LatLng(19.7750, 73.2380),
    LatLng(19.7650, 73.2350),
    LatLng(19.7600, 73.2250),
    LatLng(19.7620, 73.2100),
    LatLng(19.7700, 73.2020),
    LatLng(19.7850, 73.2000),
    LatLng(19.7950, 73.2050), // Close the polygon
  ];

  // ──────────────────────────────────────────────────────
  // CLAIM STATISTICS (Real data from government datasheet)
  // ──────────────────────────────────────────────────────

  /// Total approved IFR claims (from 2020120760 datasheet)
  static const int totalApprovedClaims = 10;

  /// Total approved forest area in sq.m
  static const int totalApprovedAreaSqm = 120000;

  /// Right type for approved claims
  static const String approvedRightType = 'Individual Forest Rights (IFR)';

  /// Caste category
  static const String casteCategory = 'अनुसूचित जमाती (Scheduled Tribes - ST)';
}
