import '../../models/village_member.dart';

/// Approximate adult member list for ओझर (Ozhar) Gram Sabha
///
/// Derived from:
/// - 10 real approved claimants from the government datasheet
/// - Extended with realistic Jawhar taluka tribal names
/// - Gender and community category assigned per village demographics:
///   ~85% ST, ~5% PVTG (Katkari), ~10% OTFD, ~50% women
///
/// Total: 50 representative members (from ~500 registered adults)
/// Used for Gram Sabha attendance tracking and quorum calculation demo.
class OzharMembersSeed {
  OzharMembersSeed._();

  static const String villageId = 'ozhar_jawhar_palghar';

  static List<VillageMember> get members => [
    // ── From real approved claimants ─────────────────
    const VillageMember(
      id: 'MBR-001', nameMarathi: 'शेवंती बोंगे', nameEnglish: 'Shevanti Bonge',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-002', nameMarathi: 'देऊ लक्ष्या फडवळे', nameEnglish: 'Deu Lakshya Phadwale',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-003', nameMarathi: 'चुनीलाल बाचू फडवळे', nameEnglish: 'Chunilal Bachu Phadwale',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-004', nameMarathi: 'सता शंकर गुरव', nameEnglish: 'Sata Shankar Gurav',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-005', nameMarathi: 'किसन गरेल', nameEnglish: 'Kisan Garel',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-006', nameMarathi: 'काशीराम देऊ दिवा', nameEnglish: 'Kashiram Deu Diwa',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-007', nameMarathi: 'शांताराम दिवा', nameEnglish: 'Shantaram Diwa',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-008', nameMarathi: 'शांताराम धर्मा काटेला', nameEnglish: 'Shantaram Dharma Katela',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-009', nameMarathi: 'रामदास बेंडू नडगे', nameEnglish: 'Ramdas Bendu Nadge',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-010', nameMarathi: 'रामजी लक्ष्मण वांगड', nameEnglish: 'Ramji Laxman Wangad',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),

    // ── Extended members (typical Jawhar taluka Warli/Kokna names) ────
    // Women — ST
    const VillageMember(
      id: 'MBR-011', nameMarathi: 'सविता रामजी वांगड', nameEnglish: 'Savita Ramji Wangad',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-012', nameMarathi: 'मंगल देऊ फडवळे', nameEnglish: 'Mangal Deu Phadwale',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-013', nameMarathi: 'लक्ष्मी किसन गरेल', nameEnglish: 'Lakshmi Kisan Garel',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-014', nameMarathi: 'सुमन शांताराम दिवा', nameEnglish: 'Suman Shantaram Diwa',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-015', nameMarathi: 'जानकी रामदास नडगे', nameEnglish: 'Janaki Ramdas Nadge',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-016', nameMarathi: 'पार्वती चुनीलाल फडवळे', nameEnglish: 'Parvati Chunilal Phadwale',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-017', nameMarathi: 'गीता काशीराम दिवा', nameEnglish: 'Geeta Kashiram Diwa',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-018', nameMarathi: 'रुक्मिणी सता गुरव', nameEnglish: 'Rukmini Sata Gurav',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-019', nameMarathi: 'तारा भीमा वाघ', nameEnglish: 'Tara Bhima Wagh',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-020', nameMarathi: 'आशा गंगा पावरा', nameEnglish: 'Asha Ganga Pawra',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),

    // Men — ST
    const VillageMember(
      id: 'MBR-021', nameMarathi: 'भीमा हरी वाघ', nameEnglish: 'Bhima Hari Wagh',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-022', nameMarathi: 'गंगा दाजी पावरा', nameEnglish: 'Ganga Daji Pawra',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-023', nameMarathi: 'सखा तुकाराम भोये', nameEnglish: 'Sakha Tukaram Bhoye',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-024', nameMarathi: 'विठ्ठल सोमा गावित', nameEnglish: 'Vitthal Soma Gavit',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-025', nameMarathi: 'हरी नामा ताडवी', nameEnglish: 'Hari Nama Tadvi',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),

    // Women — ST (more)
    const VillageMember(
      id: 'MBR-026', nameMarathi: 'सुनीता सखा भोये', nameEnglish: 'Sunita Sakha Bhoye',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-027', nameMarathi: 'माया विठ्ठल गावित', nameEnglish: 'Maya Vitthal Gavit',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-028', nameMarathi: 'रंजना हरी ताडवी', nameEnglish: 'Ranjana Hari Tadvi',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-029', nameMarathi: 'कमला गणपत बोंगे', nameEnglish: 'Kamala Ganpat Bonge',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-030', nameMarathi: 'अनिता दत्तू गरेल', nameEnglish: 'Anita Dattu Garel',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),

    // Men — ST (more)
    const VillageMember(
      id: 'MBR-031', nameMarathi: 'गणपत बापू बोंगे', nameEnglish: 'Ganpat Bapu Bonge',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-032', nameMarathi: 'दत्तू रामा गरेल', nameEnglish: 'Dattu Rama Garel',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-033', nameMarathi: 'बाबू लक्ष्मण काटेला', nameEnglish: 'Babu Laxman Katela',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-034', nameMarathi: 'तुकाराम सोमा वांगड', nameEnglish: 'Tukaram Soma Wangad',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-035', nameMarathi: 'सोमा नाथा पावरा', nameEnglish: 'Soma Natha Pawra',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),

    // Women — ST
    const VillageMember(
      id: 'MBR-036', nameMarathi: 'भागू तुकाराम वांगड', nameEnglish: 'Bhagu Tukaram Wangad',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-037', nameMarathi: 'मंजुळा बाबू काटेला', nameEnglish: 'Manjula Babu Katela',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-038', nameMarathi: 'सरस्वती सोमा पावरा', nameEnglish: 'Saraswati Soma Pawra',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),

    // PVTG — Katkari tribe (Palghar district)
    const VillageMember(
      id: 'MBR-039', nameMarathi: 'रामा धोंडू कातकरी', nameEnglish: 'Rama Dhondu Katkari',
      gender: Gender.male, category: CommunityCategory.pvtg, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-040', nameMarathi: 'सीता रामा कातकरी', nameEnglish: 'Sita Rama Katkari',
      gender: Gender.female, category: CommunityCategory.pvtg, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-041', nameMarathi: 'भानू धोंडू कातकरी', nameEnglish: 'Bhanu Dhondu Katkari',
      gender: Gender.male, category: CommunityCategory.pvtg, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-042', nameMarathi: 'जना भानू कातकरी', nameEnglish: 'Jana Bhanu Katkari',
      gender: Gender.female, category: CommunityCategory.pvtg, villageId: villageId,
    ),

    // OTFD — Other Traditional Forest Dwellers
    const VillageMember(
      id: 'MBR-043', nameMarathi: 'अशोक सूर्यकांत पाटील', nameEnglish: 'Ashok Suryakant Patil',
      gender: Gender.male, category: CommunityCategory.otfd, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-044', nameMarathi: 'सुरेखा अशोक पाटील', nameEnglish: 'Surekha Ashok Patil',
      gender: Gender.female, category: CommunityCategory.otfd, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-045', nameMarathi: 'प्रकाश रघुनाथ माळी', nameEnglish: 'Prakash Raghunath Mali',
      gender: Gender.male, category: CommunityCategory.otfd, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-046', nameMarathi: 'वैशाली प्रकाश माळी', nameEnglish: 'Vaishali Prakash Mali',
      gender: Gender.female, category: CommunityCategory.otfd, villageId: villageId,
    ),

    // More women — ST
    const VillageMember(
      id: 'MBR-047', nameMarathi: 'हिराबाई शंकर भोये', nameEnglish: 'Hirabai Shankar Bhoye',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-048', nameMarathi: 'द्रौपदी दामा वाघ', nameEnglish: 'Draupadi Dama Wagh',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-049', nameMarathi: 'यशोदा बापू गावित', nameEnglish: 'Yashoda Bapu Gavit',
      gender: Gender.female, category: CommunityCategory.st, villageId: villageId,
    ),
    const VillageMember(
      id: 'MBR-050', nameMarathi: 'दामा नाथा वाघ', nameEnglish: 'Dama Natha Wagh',
      gender: Gender.male, category: CommunityCategory.st, villageId: villageId,
    ),
  ];

  /// Counts for verification
  static int get totalMembers => members.length;
  static int get womenCount => members.where((m) => m.isWoman).length;
  static int get menCount => members.where((m) => !m.isWoman).length;
  static int get stCount => members.where((m) => m.isST).length;
  static int get pvtgCount => members.where((m) => m.isPVTG).length;
  static int get otfdCount =>
      members.where((m) => m.category == CommunityCategory.otfd).length;
}
