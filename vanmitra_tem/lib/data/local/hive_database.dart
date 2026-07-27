import 'package:hive_flutter/hive_flutter.dart';

/// Hive local database initialization and management
///
/// All data is stored locally for offline-first operation.
/// When the FastAPI backend is ready, data syncs via the sync queue.
class HiveDatabase {
  HiveDatabase._();

  // Box names
  static const String userBox = 'users';
  static const String claimsBox = 'claims';
  static const String meetingsBox = 'meetings';
  static const String resolutionsBox = 'resolutions';
  static const String attendanceBox = 'attendance';
  static const String membersBox = 'members';
  static const String hashChainBox = 'hash_chain';
  static const String settingsBox = 'settings';
  static const String syncQueueBox = 'sync_queue';
  static const String faceDataBox = 'face_data';
  static const String noticesBox = 'notices'; // Notice Board (B.3)
  // Module C boxes
  static const String localLedgerBox = 'local_ledger';       // SHA-256 hash chain
  static const String momRecordsBox = 'mom_records';         // assembled MomRecord JSON
  static const String faceEnrollmentsBox = 'face_enrollments'; // memberId → embedding

  /// Initialize Hive and open all required boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open all boxes (storing as JSON maps for flexibility)
    await Future.wait([
      Hive.openBox<Map>(userBox),
      Hive.openBox<Map>(claimsBox),
      Hive.openBox<Map>(meetingsBox),
      Hive.openBox<Map>(resolutionsBox),
      Hive.openBox<Map>(attendanceBox),
      Hive.openBox<Map>(membersBox),
      Hive.openBox<Map>(hashChainBox),
      Hive.openBox<Map>(faceDataBox),
      Hive.openBox<Map>(noticesBox),
      Hive.openBox(settingsBox),
      Hive.openBox<Map>(syncQueueBox),
      // Module C
      Hive.openBox<Map>(localLedgerBox),
      Hive.openBox<Map>(momRecordsBox),
      Hive.openBox<Map>(faceEnrollmentsBox),
    ]);
  }

  /// Check if this is the first run (no seed data loaded)
  static bool get isFirstRun {
    final settings = Hive.box(settingsBox);
    return settings.get('seeded', defaultValue: true) as bool;
  }

  /// Mark seed data as loaded
  static Future<void> markSeeded() async {
    final settings = Hive.box(settingsBox);
    await settings.put('seeded', false);
  }

  /// Get a typed box
  static Box<Map> getBox(String name) => Hive.box<Map>(name);

  /// Get settings box
  static Box get settings => Hive.box(settingsBox);

  /// Clear all data (for development/testing)
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box<Map>(userBox).clear(),
      Hive.box<Map>(claimsBox).clear(),
      Hive.box<Map>(meetingsBox).clear(),
      Hive.box<Map>(resolutionsBox).clear(),
      Hive.box<Map>(attendanceBox).clear(),
      Hive.box<Map>(membersBox).clear(),
      Hive.box<Map>(hashChainBox).clear(),
      Hive.box<Map>(faceDataBox).clear(),
      Hive.box<Map>(noticesBox).clear(),
      Hive.box(settingsBox).clear(),
      Hive.box<Map>(syncQueueBox).clear(),
      // Module C
      Hive.box<Map>(localLedgerBox).clear(),
      Hive.box<Map>(momRecordsBox).clear(),
      Hive.box<Map>(faceEnrollmentsBox).clear(),
    ]);
  }
}
