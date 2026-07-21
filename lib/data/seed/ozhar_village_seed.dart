import '../../models/village.dart';
import '../../core/constants/village_constants.dart';

/// Real village metadata for ओझर (Ozhar)
/// Source: Jawhar taluka demographics + government FRA datasheet
class OzharVillageSeed {
  OzharVillageSeed._();

  static const String villageId = 'ozhar_jawhar_palghar';

  static Village get village => Village(
    id: villageId,
    nameMarathi: 'ओझर',
    nameEnglish: 'Ozhar',
    nameHindi: 'ओझर',
    nameKonkani: 'ओझर',
    talukaMarathi: 'जव्हार',
    talukaEnglish: 'Jawhar',
    districtMarathi: 'पालघर',
    districtEnglish: 'Palghar',
    stateMarathi: 'महाराष्ट्र',
    stateEnglish: 'Maharashtra',
    totalPopulation: VillageConstants.totalPopulation,
    registeredAdultMembers: VillageConstants.registeredAdultMembers,
    registeredWomenMembers: VillageConstants.registeredWomenMembers,
    registeredMenMembers: VillageConstants.registeredMenMembers,
    stMembers: VillageConstants.stMembers,
    pvtgMembers: VillageConstants.pvtgMembers,
    otfdMembers: VillageConstants.otfdMembers,
    stPercentage: VillageConstants.stPercentage,
    pvtgPercentage: VillageConstants.pvtgPercentage,
    latitude: VillageConstants.latitude,
    longitude: VillageConstants.longitude,
    meetingVenueLat: VillageConstants.meetingVenueLat,
    meetingVenueLng: VillageConstants.meetingVenueLng,
    cfrAreaHectares: VillageConstants.cfrAreaHectares,
    totalApprovedClaims: 10,
    totalApprovedAreaSqm: 120000,
    approvedRightType: 'Individual Forest Rights (IFR)',
    casteCategory: 'अनुसूचित जमाती (Scheduled Tribes - ST)',
  );
}
