import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/hive_database.dart';
import '../models/notice.dart';
import '../models/claim.dart';

class NoticesState {
  final List<Notice> notices;
  final bool isLoading;

  const NoticesState({this.notices = const [], this.isLoading = false});

  NoticesState copyWith({List<Notice>? notices, bool? isLoading}) {
    return NoticesState(
      notices: notices ?? this.notices,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Only notices within their validity window and not dismissed
  List<Notice> get activeNotices =>
      notices.where((n) => n.isActive).toList()
        ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

  /// Critical notices shown prominently in the ticker
  List<Notice> get criticalNotices =>
      activeNotices.where((n) => n.severity == NoticeSeverity.critical).toList();
}

class NoticesNotifier extends StateNotifier<NoticesState> {
  NoticesNotifier() : super(const NoticesState());

  final _uuid = const Uuid();

  Future<void> loadNotices() async {
    state = state.copyWith(isLoading: true);
    final box = Hive.box<Map>(HiveDatabase.noticesBox);
    final notices = box.values
        .map((v) => Notice.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    state = NoticesState(notices: notices);
  }

  Future<void> addNotice(Notice notice) async {
    final box = Hive.box<Map>(HiveDatabase.noticesBox);
    await box.put(notice.noticeId, notice.toJson());
    state = state.copyWith(notices: [...state.notices, notice]);
  }

  Future<void> dismissNotice(String noticeId) async {
    final box = Hive.box<Map>(HiveDatabase.noticesBox);
    final updated = state.notices.map((n) {
      if (n.noticeId == noticeId) {
        final dismissed = n.copyWith(isDismissed: true);
        box.put(noticeId, dismissed.toJson());
        return dismissed;
      }
      return n;
    }).toList();
    state = state.copyWith(notices: updated);
  }

  /// System-generated: 60-day appeal window notice when a claim is rejected.
  Future<void> generateAppealDeadlineNotice(Claim claim) async {
    if (claim.appealDeadline == null) return;
    final daysLeft = claim.appealDaysRemaining;
    if (daysLeft <= 0) return;

    final notice = Notice(
      noticeId: _uuid.v4(),
      category: NoticeCategory.claimDeadline,
      titleByLang: {
        'mr': 'अपील मुदत: ${claim.claimantName}',
        'en': 'Appeal Deadline: ${claim.claimantName}',
      },
      bodyByLang: {
        'mr': 'दावा नामंजूर झाला. अपील करण्यासाठी $daysLeft दिवस शिल्लक आहेत.',
        'en':
            'Claim was rejected. $daysLeft days remaining to file appeal under Section 6.',
      },
      severity: daysLeft <= 7 ? NoticeSeverity.critical : NoticeSeverity.warning,
      validFrom: DateTime.now(),
      validUntil: claim.appealDeadline!,
      linkedClaimId: claim.id,
      source: NoticeSource.systemGenerated,
      createdAt: DateTime.now(),
    );
    await addNotice(notice);
  }

  /// Admin action: post a custom notice (e.g. Gram Sabha meeting schedule).
  Future<void> postAdminNotice({
    required String titleMr,
    required String titleEn,
    required String bodyMr,
    required String bodyEn,
    required NoticeCategory category,
    required NoticeSeverity severity,
    required DateTime validUntil,
    String? linkedMeetingId,
    String? linkedClaimId,
  }) async {
    final notice = Notice(
      noticeId: _uuid.v4(),
      category: category,
      titleByLang: {'mr': titleMr, 'en': titleEn},
      bodyByLang: {'mr': bodyMr, 'en': bodyEn},
      severity: severity,
      validFrom: DateTime.now(),
      validUntil: validUntil,
      linkedMeetingId: linkedMeetingId,
      linkedClaimId: linkedClaimId,
      source: NoticeSource.adminPosted,
      createdAt: DateTime.now(),
    );
    await addNotice(notice);
  }
}

final noticesProvider =
    StateNotifierProvider<NoticesNotifier, NoticesState>((ref) {
  return NoticesNotifier();
});
