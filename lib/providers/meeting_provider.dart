import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/hive_database.dart';
import '../data/seed/ozhar_members_seed.dart';
import '../models/attendance_record.dart';
import '../models/gram_sabha_meeting.dart';
import '../models/village_member.dart';
import '../models/resolution.dart';
import '../models/quorum_status.dart';
import '../services/hash_chain_service.dart';
import '../services/quorum_service.dart';
import '../services/firestore_service.dart';
import '../models/sync_item.dart';

const _uuid = Uuid();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBERS PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MembersNotifier extends StateNotifier<List<VillageMember>> {
  MembersNotifier() : super([]);

  Future<void> loadMembers(String villageId) async {
    final box = Hive.box<Map>(HiveDatabase.membersBox);
    if (box.isEmpty) {
      for (final m in OzharMembersSeed.members) {
        await box.put(m.id, m.toJson());
      }
    }
    state = box.values
        .map((v) => VillageMember.fromJson(Map<String, dynamic>.from(v)))
        .where((m) => m.villageId == villageId)
        .toList();
  }
}

final membersProvider =
    StateNotifierProvider<MembersNotifier, List<VillageMember>>((ref) {
  return MembersNotifier();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEETINGS PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MeetingsState {
  final List<GramSabhaMeeting> meetings;
  final GramSabhaMeeting? activeMeeting;
  final bool isLoading;

  const MeetingsState({
    this.meetings = const [],
    this.activeMeeting,
    this.isLoading = false,
  });

  MeetingsState copyWith({
    List<GramSabhaMeeting>? meetings,
    GramSabhaMeeting? activeMeeting,
    bool? isLoading,
    bool clearActive = false,
  }) {
    return MeetingsState(
      meetings: meetings ?? this.meetings,
      activeMeeting: clearActive ? null : (activeMeeting ?? this.activeMeeting),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<GramSabhaMeeting> get upcomingMeetings =>
      meetings.where((m) => m.isUpcoming).toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

  List<GramSabhaMeeting> get pastMeetings =>
      meetings.where((m) => m.status == MeetingStatus.completed).toList()
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

  GramSabhaMeeting? get todayMeeting {
    try {
      return meetings.firstWhere((m) => m.isToday && m.isAcceptingAttendance);
    } catch (_) {
      return null;
    }
  }
}

class MeetingsNotifier extends StateNotifier<MeetingsState> {
  MeetingsNotifier() : super(const MeetingsState());

  Future<void> loadMeetings(String villageId) async {
    state = state.copyWith(isLoading: true);
    final box = Hive.box<Map>(HiveDatabase.meetingsBox);
    final meetings = box.values
        .map((v) => GramSabhaMeeting.fromJson(Map<String, dynamic>.from(v)))
        .where((m) => m.villageId == villageId)
        .toList();
    state = MeetingsState(meetings: meetings);
  }

  Future<GramSabhaMeeting> createMeeting({
    required String villageId,
    required DateTime scheduledDate,
    required MeetingType type,
    required String venue,
    required double venueLat,
    required double venueLng,
    required String createdByUserId,
    String? agenda,
  }) async {
    final meeting = GramSabhaMeeting(
      id: _uuid.v4(),
      villageId: villageId,
      scheduledDate: scheduledDate,
      type: type,
      status: MeetingStatus.scheduled,
      venue: venue,
      venueLat: venueLat,
      venueLng: venueLng,
      createdByUserId: createdByUserId,
      agenda: agenda,
    );
    final box = Hive.box<Map>(HiveDatabase.meetingsBox);
    await box.put(meeting.id, meeting.toJson());
    state = state.copyWith(meetings: [...state.meetings, meeting]);

    // FIX (Problem 5): Enqueue sync item so meeting is pushed to Firestore.
    // Previously createMeeting() saved to Hive but never enqueued a SyncItem,
    // meaning new meetings were never pushed to Firestore by CloudSyncService.
    // _updateMeeting() already had this logic — this brings createMeeting() in line.
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.createMeeting,
      status: SyncStatus.pending,
      entityId: meeting.id,
      entityType: 'meeting',
      payload: meeting.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());

    return meeting;
  }

  Future<void> startMeeting(String meetingId) async {
    final meeting = state.meetings.firstWhere((m) => m.id == meetingId);
    final updated = meeting.copyWith(
      status: MeetingStatus.inProgress,
      startedAt: DateTime.now(),
    );
    await _updateMeeting(updated);
    state = state.copyWith(activeMeeting: updated);
  }

  Future<void> completeMeeting(String meetingId, {
    int totalAttendees = 0,
    int womenAttendees = 0,
    int stAttendees = 0,
    int pvtgAttendees = 0,
    bool quorumValid = false,
  }) async {
    final meeting = state.meetings.firstWhere((m) => m.id == meetingId);
    final updated = meeting.copyWith(
      status: MeetingStatus.completed,
      completedAt: DateTime.now(),
      totalAttendees: totalAttendees,
      womenAttendees: womenAttendees,
      stAttendees: stAttendees,
      pvtgAttendees: pvtgAttendees,
      quorumValid: quorumValid,
    );
    await _updateMeeting(updated);
    state = state.copyWith(clearActive: true);
  }

  Future<void> _updateMeeting(GramSabhaMeeting meeting) async {
    final box = Hive.box<Map>(HiveDatabase.meetingsBox);
    await box.put(meeting.id, meeting.toJson());
    final updated = state.meetings.map((m) => m.id == meeting.id ? meeting : m).toList();
    state = state.copyWith(meetings: updated);

    // Enqueue sync item
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.updateMeeting,
      status: SyncStatus.pending,
      entityId: meeting.id,
      entityType: 'meeting',
      payload: meeting.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());
  }
}

final meetingsProvider =
    StateNotifierProvider<MeetingsNotifier, MeetingsState>((ref) {
  return MeetingsNotifier();
});

/// Real-time stream of meetings from Firestore
final meetingsStreamProvider = StreamProvider.family<List<GramSabhaMeeting>, String>((ref, villageId) {
  return FirestoreService().streamMeetings(villageId).map((snapshot) =>
      snapshot.docs.map((d) => GramSabhaMeeting.fromJson(d.data() as Map<String, dynamic>)).toList());
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ATTENDANCE PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  AttendanceNotifier() : super([]);

  Future<void> loadAttendance(String meetingId) async {
    final box = Hive.box<Map>(HiveDatabase.attendanceBox);
    state = box.values
        .map((v) => AttendanceRecord.fromJson(Map<String, dynamic>.from(v)))
        .where((a) => a.meetingId == meetingId)
        .toList();
  }

  Future<void> addRecord(AttendanceRecord record) async {
    final box = Hive.box<Map>(HiveDatabase.attendanceBox);
    await box.put(record.id, record.toJson());
    state = [...state, record];

    // Enqueue sync item
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.markAttendance,
      status: SyncStatus.pending,
      entityId: record.id,
      entityType: 'attendance',
      payload: record.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());
  }

  bool isMemberCheckedIn(String memberId) {
    return state.any((r) => r.memberId == memberId);
  }

  QuorumStatus getQuorumStatus(List<VillageMember> allMembers, MeetingType type) {
    final service = QuorumService();
    return service.calculateQuorum(
      attendanceRecords: state,
      allMembers: allMembers,
      meetingType: type,
    );
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
  return AttendanceNotifier();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RESOLUTION PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ResolutionNotifier extends StateNotifier<List<Resolution>> {
  final HashChainService _hashService = HashChainService();

  ResolutionNotifier() : super([]);

  Future<void> loadResolutions(String villageId) async {
    final box = Hive.box<Map>(HiveDatabase.resolutionsBox);
    state = box.values
        .map((v) => Resolution.fromJson(Map<String, dynamic>.from(v)))
        .where((r) => r.villageId == villageId)
        .toList()
      ..sort((a, b) => a.blockIndex.compareTo(b.blockIndex));
  }

  Future<Resolution> addResolution({
    required String meetingId,
    required String villageId,
    required ResolutionType type,
    required String text,
    required String recordedByUserId,
    required QuorumStatus quorum,
    String? summary,
    String? relatedClaimId,
  }) async {
    // Get the chain for hash computation
    final chainBox = Hive.box<Map>(HiveDatabase.hashChainBox);
    HashBlock previousBlock;

    if (chainBox.isEmpty) {
      // Create genesis block
      previousBlock = _hashService.createGenesisBlock(villageId: villageId);
      await chainBox.put('genesis_$villageId', previousBlock.toJson());
    } else {
      // Get last block
      final blocks = chainBox.values
          .map((v) => HashBlock.fromJson(Map<String, dynamic>.from(v)))
          .where((b) => b.villageId == villageId)
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      previousBlock = blocks.last;
    }

    final isCompliant = type.requiresEnhancedQuorum
        ? quorum.isEnhancedQuorumValid
        : quorum.isStandardQuorumValid;

    final resolutionId = _uuid.v4();

    // Create hash block
    final newBlock = _hashService.addBlock(
      previousBlock: previousBlock,
      resolutionId: resolutionId,
      resolutionText: text,
      resolutionType: type.name,
      totalPresent: quorum.totalPresent,
      totalRegistered: quorum.totalRegistered,
      womenPresent: quorum.womenPresent,
      stPresent: quorum.stPresent,
      pvtgPresent: quorum.pvtgPresent,
      quorumValid: quorum.isValid,
      isCompliant: isCompliant,
      villageId: villageId,
    );

    await chainBox.put('block_${newBlock.index}_$villageId', newBlock.toJson());

    final resolution = Resolution(
      id: resolutionId,
      meetingId: meetingId,
      villageId: villageId,
      type: type,
      text: text,
      summary: summary,
      timestamp: newBlock.timestamp,
      recordedByUserId: recordedByUserId,
      quorumValid: quorum.isValid,
      totalPresent: quorum.totalPresent,
      totalRegistered: quorum.totalRegistered,
      womenPresent: quorum.womenPresent,
      stPresent: quorum.stPresent,
      pvtgPresent: quorum.pvtgPresent,
      attendancePercentage: quorum.attendancePercentage,
      womenPercentage: quorum.womenPercentage,
      hash: newBlock.hash,
      previousHash: newBlock.previousHash,
      blockIndex: newBlock.index,
      relatedClaimId: relatedClaimId,
      isCompliant: isCompliant,
    );

    final resBox = Hive.box<Map>(HiveDatabase.resolutionsBox);
    await resBox.put(resolution.id, resolution.toJson());

    state = [...state, resolution];
    
    // Enqueue sync item
    final syncBox = Hive.box<Map>(HiveDatabase.syncQueueBox);
    final syncItem = SyncItem(
      id: const Uuid().v4(),
      action: SyncAction.createResolution,
      status: SyncStatus.pending,
      entityId: resolution.id,
      entityType: 'resolution',
      payload: resolution.toJson(),
      createdAt: DateTime.now(),
    );
    await syncBox.put(syncItem.id, syncItem.toJson());

    return resolution;
  }

  /// Verify entire hash chain integrity
  ChainVerificationResult verifyChain(String villageId) {
    final chainBox = Hive.box<Map>(HiveDatabase.hashChainBox);
    final blocks = chainBox.values
        .map((v) => HashBlock.fromJson(Map<String, dynamic>.from(v)))
        .where((b) => b.villageId == villageId)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return _hashService.verifyChain(blocks);
  }
}

final resolutionProvider =
    StateNotifierProvider<ResolutionNotifier, List<Resolution>>((ref) {
  return ResolutionNotifier();
});
