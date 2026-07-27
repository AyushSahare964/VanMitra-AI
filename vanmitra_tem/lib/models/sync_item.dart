/// Offline sync queue item
///
/// Stores actions taken offline that need to be synced
/// to the FastAPI backend when connectivity is available.
enum SyncAction {
  createClaim,
  updateClaim,
  submitClaim,
  createMeeting,
  updateMeeting,
  markAttendance,
  createResolution,
  enrollFace,
  reportAlert,
  // Module C
  publishMomRecord,     // push assembled MomRecord to Firestore
  syncFaceEnrollment,   // push face embedding (128-dim vector) to Firestore
}

enum SyncStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class SyncItem {
  final String id;
  final SyncAction action;
  final SyncStatus status;
  final String entityId; // ID of the claim/meeting/etc.
  final String entityType; // 'claim', 'meeting', 'attendance', etc.
  final Map<String, dynamic> payload; // Full data to sync
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;

  const SyncItem({
    required this.id,
    required this.action,
    required this.status,
    required this.entityId,
    required this.entityType,
    required this.payload,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.errorMessage,
  });

  SyncItem copyWith({
    SyncStatus? status,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? errorMessage,
  }) {
    return SyncItem(
      id: id,
      action: action,
      status: status ?? this.status,
      entityId: entityId,
      entityType: entityType,
      payload: payload,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.name,
    'status': status.name,
    'entityId': entityId,
    'entityType': entityType,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'attemptCount': attemptCount,
    'errorMessage': errorMessage,
  };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
    id: json['id'] as String,
    action: SyncAction.values.byName(json['action'] as String),
    status: SyncStatus.values.byName(json['status'] as String),
    entityId: json['entityId'] as String,
    entityType: json['entityType'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAttemptAt: json['lastAttemptAt'] != null
        ? DateTime.parse(json['lastAttemptAt'] as String)
        : null,
    attemptCount: json['attemptCount'] as int? ?? 0,
    errorMessage: json['errorMessage'] as String?,
  );
}
