/// Rule 13 evidence categories for FRA claims
/// Source: FRA Rules 2008, Rule 13
///
/// Defines the admissible categories of evidence that a Forest Rights
/// Committee and Gram Sabha may use to verify a claim.
class EvidenceCategory {
  final String key;
  final String nameEn;
  final String nameMr;
  final String nameHi;
  final String nameKn;
  final String descriptionEn;
  final String descriptionMr;
  final double weight; // For evidence-completeness score
  final String iconName;
  final List<String> examplesEn;
  final List<String> examplesMr;

  const EvidenceCategory({
    required this.key,
    required this.nameEn,
    required this.nameMr,
    required this.nameHi,
    required this.nameKn,
    required this.descriptionEn,
    required this.descriptionMr,
    required this.weight,
    required this.iconName,
    this.examplesEn = const [],
    this.examplesMr = const [],
  });
}

/// All Rule 13 evidence categories with descriptions and examples
class EvidenceCategories {
  EvidenceCategories._();

  static const List<EvidenceCategory> all = [
    EvidenceCategory(
      key: 'government_records',
      nameEn: 'Government Records',
      nameMr: 'शासकीय नोंदी',
      nameHi: 'सरकारी अभिलेख',
      nameKn: 'सरकारी नोंदणी',
      descriptionEn: 'Official documents proving identity and residence',
      descriptionMr: 'ओळख आणि निवास सिद्ध करणारी अधिकृत कागदपत्रे',
      weight: 0.25,
      iconName: 'description',
      examplesEn: [
        'Voter ID / Election Commission records',
        'Ration Card',
        'Land revenue records',
        'Court orders or proceedings',
        'Forest Department records',
      ],
      examplesMr: [
        'मतदार ओळखपत्र / निवडणूक आयोग नोंदी',
        'रेशनकार्ड',
        'महसूल नोंदी',
        'न्यायालयीन आदेश',
        'वन विभाग नोंदी',
      ],
    ),
    EvidenceCategory(
      key: 'physical_attestation',
      nameEn: 'Physical Structures',
      nameMr: 'भौतिक संरचना',
      nameHi: 'भौतिक संरचनाएं',
      nameKn: 'भौतिक संरचना',
      descriptionEn: 'Permanent improvements on the land showing occupation',
      descriptionMr: 'जमिनीवर कायम स्वरूपाच्या सुधारणा दर्शवणारे पुरावे',
      weight: 0.25,
      iconName: 'home_work',
      examplesEn: [
        'Houses or huts on the land',
        'Wells, bunds, or irrigation channels',
        'Fencing or boundary markers',
        'Crops or plantations',
      ],
      examplesMr: [
        'जमिनीवरील घरे किंवा झोपड्या',
        'विहिरी, बांध किंवा सिंचन नाले',
        'कुंपण किंवा सीमा चिन्हे',
        'पिके किंवा वृक्षारोपण',
      ],
    ),
    EvidenceCategory(
      key: 'satellite_imagery',
      nameEn: 'Satellite / Aerial Imagery',
      nameMr: 'उपग्रह / हवाई छायाचित्रे',
      nameHi: 'उपग्रह / हवाई चित्र',
      nameKn: 'उपग्रह / हवाई छायाचित्रे',
      descriptionEn: 'Historical imagery showing occupation or cultivation',
      descriptionMr: 'व्यापार किंवा शेती दर्शवणारी ऐतिहासिक उपग्रह छायाचित्रे',
      weight: 0.15,
      iconName: 'satellite_alt',
      examplesEn: [
        'Satellite images showing land use before 13.12.2005',
        'Google Earth historical imagery',
        'ISRO Bhuvan imagery',
      ],
      examplesMr: [
        '१३.१२.२००५ पूर्वीचे भू-वापर दर्शवणारे उपग्रह छायाचित्रे',
        'गूगल अर्थ ऐतिहासिक छायाचित्रे',
        'इस्रो भुवन छायाचित्रे',
      ],
    ),
    EvidenceCategory(
      key: 'elder_statements',
      nameEn: 'Statements of Elders',
      nameMr: 'वडीलधाऱ्यांची निवेदने',
      nameHi: 'बड़े-बुजुर्गों के बयान',
      nameKn: 'वडिलधाऱ्यांचीं निवेदनां',
      descriptionEn: 'Sworn statements from at least 2 elder neighbours',
      descriptionMr: 'किमान २ वडीलधारी शेजाऱ्यांचे शपथपत्र',
      weight: 0.15,
      iconName: 'people',
      examplesEn: [
        'Written statements from 2 or more elders',
        'Attestation by village elders',
        'Community verification statements',
      ],
      examplesMr: [
        '२ किंवा अधिक वडीलधाऱ्यांचे लिखित निवेदन',
        'ग्रामवृद्धांचे साक्षांकन',
        'समुदाय पडताळणी निवेदन',
      ],
    ),
    EvidenceCategory(
      key: 'traditional_structures',
      nameEn: 'Traditional Community Structures',
      nameMr: 'पारंपरिक सामुदायिक संरचना',
      nameHi: 'पारंपरिक सामुदायिक संरचनाएं',
      nameKn: 'पारंपारीक समुदाय संरचना',
      descriptionEn: 'Sacred groves, burial sites, or customary markers',
      descriptionMr: 'पवित्र वनखंड, दफनभूमी किंवा प्रथागत चिन्हे',
      weight: 0.10,
      iconName: 'forest',
      examplesEn: [
        'Sacred groves (dev rai)',
        'Burial or cremation sites',
        'Customary boundary markers',
        'Traditional water sources',
      ],
      examplesMr: [
        'पवित्र वनखंड (देवराई)',
        'दफनभूमी किंवा स्मशानभूमी',
        'प्रथागत सीमा चिन्हे',
        'पारंपरिक जलस्रोत',
      ],
    ),
    EvidenceCategory(
      key: 'other_govt_schemes',
      nameEn: 'Other Government Scheme Evidence',
      nameMr: 'इतर शासकीय योजना पुरावे',
      nameHi: 'अन्य सरकारी योजना प्रमाण',
      nameKn: 'इतर सरकारी योजना पुरावे',
      descriptionEn: 'Evidence from other government programmes',
      descriptionMr: 'इतर शासकीय कार्यक्रमांचे पुरावे',
      weight: 0.10,
      iconName: 'badge',
      examplesEn: [
        'MGNREGA job card showing work in the area',
        'Ration card allocation records',
        'Anganwadi / health scheme records',
        'BPL survey records',
      ],
      examplesMr: [
        'मनरेगा जॉबकार्ड',
        'रेशन कार्ड वाटप नोंदी',
        'अंगणवाडी / आरोग्य योजना नोंदी',
        'बीपीएल सर्वेक्षण नोंदी',
      ],
    ),
  ];

  /// Get category by key
  static EvidenceCategory? getByKey(String key) {
    try {
      return all.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }
}
