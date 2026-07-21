import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_database.dart';
import '../models/mom_record.dart';
import '../services/audio_capture_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/embedding_matcher.dart';
import '../services/face_enrollment.dart';
import '../services/local_ledger_service.dart';
import '../services/mom_assembly_service.dart';
import '../services/mom_pdf_service.dart';
import '../services/ondevice_stt_service.dart';
import '../services/ondevice_translation_service.dart';
import '../services/quorum_engine.dart';

// ── Service singletons (lazy, initialised once at first use) ─────────────────

/// FaceEnrollmentService — loads facenet.tflite from assets on first access.
/// Call [faceEnrollmentServiceProvider.read(ref).init()] at app startup.
final faceEnrollmentServiceProvider = Provider<FaceEnrollmentService>((ref) {
  final service = FaceEnrollmentService(threshold: 0.55);
  ref.onDispose(service.dispose);
  return service;
});

final embeddingMatcherProvider = Provider<EmbeddingMatcher>((ref) {
  return const EmbeddingMatcher(threshold: 0.55);
});

/// [LocalLedgerService] is village-scoped — pass villageId when constructing.
/// The [localLedgerProvider] family creates one instance per villageId.
final localLedgerProvider =
    Provider.family<LocalLedgerService, String>((ref, villageId) {
  return LocalLedgerService(villageId);
});

final sttServiceProvider = Provider<OnDeviceSttService>((ref) {
  final service = OnDeviceSttService();
  ref.onDispose(service.dispose);
  return service;
});

final translationServiceProvider =
    Provider<OnDeviceTranslationService>((ref) {
  final service = OnDeviceTranslationService();
  ref.onDispose(service.dispose);
  return service;
});

/// [MomAssemblyService] is village-scoped to get the correct [LocalLedgerService].
final momAssemblyProvider =
    Provider.family<MomAssemblyService, String>((ref, villageId) {
  final ledger = ref.watch(localLedgerProvider(villageId));
  return MomAssemblyService(ledger: ledger);
});

final momPdfServiceProvider = Provider<MomPdfService>((ref) => MomPdfService());

final audioCaptureProvider = Provider<AudioCaptureService>((ref) {
  final service = AudioCaptureService();
  ref.onDispose(service.dispose);
  return service;
});

// ── State: live attendance for current meeting session ───────────────────────

class AttendanceNotifier extends StateNotifier<List<AttendanceEntry>> {
  AttendanceNotifier() : super([]);

  void addEntry(AttendanceEntry entry) {
    // Idempotent — do not add the same member twice
    if (state.any((e) => e.memberId == entry.memberId)) return;
    state = [...state, entry];
  }

  void removeEntry(String memberId) {
    state = state.where((e) => e.memberId != memberId).toList();
  }

  void clear() => state = [];
}

final activeAttendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceEntry>>(
  (ref) => AttendanceNotifier(),
);

// ── State: face enrollments (memberId → 128-dim embedding) ───────────────────

class FaceEnrollmentsNotifier
    extends StateNotifier<Map<String, List<double>>> {
  FaceEnrollmentsNotifier() : super({});

  void addEnrollment(String memberId, List<double> embedding) {
    state = {...state, memberId: embedding};
    // Persist locally to Hive
    Hive.box<Map>(HiveDatabase.faceEnrollmentsBox)
        .put(memberId, {'memberId': memberId, 'embedding': embedding});
  }

  void removeEnrollment(String memberId) {
    final newState = Map<String, List<double>>.from(state);
    newState.remove(memberId);
    state = newState;
    Hive.box<Map>(HiveDatabase.faceEnrollmentsBox).delete(memberId);
  }

  /// Load all saved embeddings from Hive into state (call at app startup).
  void loadFromHive() {
    final box = Hive.box<Map>(HiveDatabase.faceEnrollmentsBox);
    final loaded = <String, List<double>>{};
    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry != null) {
        final raw = entry['embedding'] as List<dynamic>?;
        if (raw != null) {
          loaded[key as String] =
              raw.map((e) => (e as num).toDouble()).toList();
        }
      }
    }
    state = loaded;
  }
}

final faceEnrollmentsProvider =
    StateNotifierProvider<FaceEnrollmentsNotifier, Map<String, List<double>>>(
  (ref) => FaceEnrollmentsNotifier(),
);

// ── State: MoM records (assembled + synced) ───────────────────────────────────

class MomRecordsNotifier extends StateNotifier<List<MomRecord>> {
  MomRecordsNotifier() : super([]);

  /// Load all MoM records for a village from Hive into state.
  void loadFromHive(String villageId) {
    final box = Hive.box<Map>(HiveDatabase.momRecordsBox);
    final records = box.values
        .map((v) => Map<String, dynamic>.from(v))
        .where((m) => m['villageId'] == villageId)
        .map(MomRecord.fromJson)
        .toList()
      ..sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
    state = records;
  }

  /// Add a new MoM record (post-assembly) and persist to Hive.
  Future<void> addRecord(MomRecord record) async {
    await Hive.box<Map>(HiveDatabase.momRecordsBox)
        .put(record.id, record.toJson());
    state = [...state, record];
  }

  /// Update a record after Firestore sync (set isSynced=true + canonicalHash).
  Future<void> markSynced({
    required String recordId,
    required String canonicalHash,
    required String firestoreTimestamp,
  }) async {
    final index = state.indexWhere((r) => r.id == recordId);
    if (index == -1) return;
    final updated = state[index].copyWith(
      canonicalHash: canonicalHash,
      firestoreTimestamp: firestoreTimestamp,
      isSynced: true,
    );
    final newState = List<MomRecord>.from(state);
    newState[index] = updated;
    state = newState;
    await Hive.box<Map>(HiveDatabase.momRecordsBox)
        .put(recordId, updated.toJson());
  }
}

final momRecordsProvider =
    StateNotifierProvider<MomRecordsNotifier, List<MomRecord>>(
  (ref) => MomRecordsNotifier(),
);

// ── Translation model readiness ───────────────────────────────────────────────

/// True once [OnDeviceTranslationService.ensureModelsReady()] has completed.
/// Used to show a progress indicator on the first-run onboarding screen.
final translationReadyProvider = StateProvider<bool>((ref) => false);

/// True once [FaceEnrollmentService.init()] has completed loading facenet.tflite.
final faceModelReadyProvider = StateProvider<bool>((ref) => false);
