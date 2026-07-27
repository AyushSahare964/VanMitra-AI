import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seed/ozhar_village_seed.dart';
import '../models/village.dart';

/// Village state provider
///
/// FIX (Problem 6): Previously always loaded OzharVillageSeed regardless of
/// villageId — every user saw "ओझर" even if registered in a different village.
/// Now fetches the village document from Firestore by the user's real villageId.
/// Seed data is only used as a fallback for the demo village 'ozhar_01'.
class VillageNotifier extends StateNotifier<Village?> {
  VillageNotifier() : super(null);

  Future<void> loadVillage(String villageId) async {
    if (villageId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('villages')
          .doc(villageId)
          .get();
      if (doc.exists && doc.data() != null) {
        state = Village.fromJson(doc.data()!);
        return;
      }
    } catch (_) {
      // Network/Firestore failure — fall through to seed fallback
    }
    // Fallback: only use seed data for the Ozhar demo village
    if (villageId == 'ozhar_01') {
      state = OzharVillageSeed.village;
    }
  }

  void setVillage(Village village) {
    state = village;
  }
}

final villageProvider = StateNotifierProvider<VillageNotifier, Village?>((ref) {
  return VillageNotifier();
});
