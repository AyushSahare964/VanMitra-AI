import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../services/cloud_sync_service.dart';

enum SyncState {
  synced,
  pending,
  offline,
}

/// Unified SyncStatusChip displaying real-time Hive offline queue vs Cloud Firestore sync state.
/// Used directly in AppHeader and inside Profile/Settings diagnostics cards.
class SyncStatusChip extends ConsumerWidget {
  final bool showLabel;
  final bool isLight;

  const SyncStatusChip({
    super.key,
    this.showLabel = true,
    this.isLight = true, // true when placed on dark forestCanopy header
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Monitor CloudSyncService via Hive syncQueueBox size if available or general state
    // We check the pending queue size directly from CloudSyncService
    final pendingCount = CloudSyncService.pendingItemCount;
    final state = pendingCount > 0 ? SyncState.pending : SyncState.synced;

    Color dotColor;
    String text;
    Color bg;
    Color textColor;

    if (state == SyncState.synced) {
      dotColor = AppColors.successGreen;
      text = 'Synced';
      bg = isLight ? Colors.white.withValues(alpha: 0.15) : AppColors.successGreen.withValues(alpha: 0.1);
      textColor = isLight ? Colors.white : AppColors.successGreen;
    } else if (state == SyncState.pending) {
      dotColor = AppColors.warningAmber;
      text = '$pendingCount Pending';
      bg = isLight ? Colors.white.withValues(alpha: 0.15) : AppColors.warningAmber.withValues(alpha: 0.15);
      textColor = isLight ? AppColors.warningAmber : AppColors.warningAmber;
    } else {
      dotColor = AppColors.textTertiary;
      text = 'Offline';
      bg = isLight ? Colors.white.withValues(alpha: 0.15) : AppColors.textTertiary.withValues(alpha: 0.15);
      textColor = isLight ? Colors.white70 : AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: isLight ? Border.all(color: Colors.white.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: state == SyncState.synced || state == SyncState.pending
                  ? [BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 4)]
                  : null,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
