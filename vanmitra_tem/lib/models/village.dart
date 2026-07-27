/// Village model — represents a village in the VanMitra-AI system
class Village {
  final String id;
  final String nameMarathi;
  final String nameEnglish;
  final String nameHindi;
  final String nameKonkani;
  final String talukaMarathi;
  final String talukaEnglish;
  final String districtMarathi;
  final String districtEnglish;
  final String stateMarathi;
  final String stateEnglish;

  // Demographics
  final int totalPopulation;
  final int registeredAdultMembers;
  final int registeredWomenMembers;
  final int registeredMenMembers;
  final int stMembers;
  final int pvtgMembers;
  final int otfdMembers;
  final double stPercentage;
  final double pvtgPercentage;

  // Geography
  final double latitude;
  final double longitude;
  final double meetingVenueLat;
  final double meetingVenueLng;
  final double cfrAreaHectares;

  // Claim statistics
  final int totalApprovedClaims;
  final int totalApprovedAreaSqm;
  final String approvedRightType;
  final String casteCategory;

  const Village({
    required this.id,
    required this.nameMarathi,
    required this.nameEnglish,
    this.nameHindi = '',
    this.nameKonkani = '',
    required this.talukaMarathi,
    required this.talukaEnglish,
    required this.districtMarathi,
    required this.districtEnglish,
    required this.stateMarathi,
    required this.stateEnglish,
    required this.totalPopulation,
    required this.registeredAdultMembers,
    required this.registeredWomenMembers,
    required this.registeredMenMembers,
    this.stMembers = 0,
    this.pvtgMembers = 0,
    this.otfdMembers = 0,
    this.stPercentage = 0.0,
    this.pvtgPercentage = 0.0,
    required this.latitude,
    required this.longitude,
    required this.meetingVenueLat,
    required this.meetingVenueLng,
    this.cfrAreaHectares = 0.0,
    this.totalApprovedClaims = 0,
    this.totalApprovedAreaSqm = 0,
    this.approvedRightType = '',
    this.casteCategory = '',
  });

  /// Full location string
  String get fullLocationEn =>
      '$nameEnglish, $talukaEnglish, $districtEnglish, $stateEnglish';

  String get fullLocationMr =>
      '$nameMarathi, $talukaMarathi, $districtMarathi, $stateMarathi';

  /// Total approved area in hectares
  double get totalApprovedAreaHectares => totalApprovedAreaSqm / 10000;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameMarathi': nameMarathi,
    'nameEnglish': nameEnglish,
    'nameHindi': nameHindi,
    'nameKonkani': nameKonkani,
    'talukaMarathi': talukaMarathi,
    'talukaEnglish': talukaEnglish,
    'districtMarathi': districtMarathi,
    'districtEnglish': districtEnglish,
    'stateMarathi': stateMarathi,
    'stateEnglish': stateEnglish,
    'totalPopulation': totalPopulation,
    'registeredAdultMembers': registeredAdultMembers,
    'registeredWomenMembers': registeredWomenMembers,
    'registeredMenMembers': registeredMenMembers,
    'stMembers': stMembers,
    'pvtgMembers': pvtgMembers,
    'otfdMembers': otfdMembers,
    'stPercentage': stPercentage,
    'pvtgPercentage': pvtgPercentage,
    'latitude': latitude,
    'longitude': longitude,
    'meetingVenueLat': meetingVenueLat,
    'meetingVenueLng': meetingVenueLng,
    'cfrAreaHectares': cfrAreaHectares,
    'totalApprovedClaims': totalApprovedClaims,
    'totalApprovedAreaSqm': totalApprovedAreaSqm,
    'approvedRightType': approvedRightType,
    'casteCategory': casteCategory,
  };

  factory Village.fromJson(Map<String, dynamic> json) => Village(
    id: json['id'] as String,
    nameMarathi: json['nameMarathi'] as String,
    nameEnglish: json['nameEnglish'] as String,
    nameHindi: json['nameHindi'] as String? ?? '',
    nameKonkani: json['nameKonkani'] as String? ?? '',
    talukaMarathi: json['talukaMarathi'] as String,
    talukaEnglish: json['talukaEnglish'] as String,
    districtMarathi: json['districtMarathi'] as String,
    districtEnglish: json['districtEnglish'] as String,
    stateMarathi: json['stateMarathi'] as String,
    stateEnglish: json['stateEnglish'] as String,
    totalPopulation: json['totalPopulation'] as int,
    registeredAdultMembers: json['registeredAdultMembers'] as int,
    registeredWomenMembers: json['registeredWomenMembers'] as int,
    registeredMenMembers: json['registeredMenMembers'] as int,
    stMembers: json['stMembers'] as int? ?? 0,
    pvtgMembers: json['pvtgMembers'] as int? ?? 0,
    otfdMembers: json['otfdMembers'] as int? ?? 0,
    stPercentage: (json['stPercentage'] as num?)?.toDouble() ?? 0.0,
    pvtgPercentage: (json['pvtgPercentage'] as num?)?.toDouble() ?? 0.0,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    meetingVenueLat: (json['meetingVenueLat'] as num).toDouble(),
    meetingVenueLng: (json['meetingVenueLng'] as num).toDouble(),
    cfrAreaHectares: (json['cfrAreaHectares'] as num?)?.toDouble() ?? 0.0,
    totalApprovedClaims: json['totalApprovedClaims'] as int? ?? 0,
    totalApprovedAreaSqm: json['totalApprovedAreaSqm'] as int? ?? 0,
    approvedRightType: json['approvedRightType'] as String? ?? '',
    casteCategory: json['casteCategory'] as String? ?? '',
  );
}
