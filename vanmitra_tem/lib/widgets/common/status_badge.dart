import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum StatusBadgeType {
  success,      // Approved, Quorum Met, Synced
  warning,      // Pending Review, Borderline Quorum, Offline Queue
  danger,       // Rejected, Tampered, Alert Tier 1
  info,         // GPS Verified, Face Verified, General Info
  institutional,// Govt / Legal Official Seal
  verified,     // Alias for success
  pending,      // Alias for warning
  error,        // Alias for danger
}

typedef StatusType = StatusBadgeType;

/// One shared pill StatusBadge component across all screens with semantic coloring and dual parameter support.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final StatusBadgeType? status;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
    this.status,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    final effectiveType = status ?? type;

    switch (effectiveType) {
      case StatusBadgeType.success:
      case StatusBadgeType.verified:
        textColor = AppColors.successGreen;
        bgColor = AppColors.successGreen.withValues(alpha: 0.12);
        break;
      case StatusBadgeType.warning:
      case StatusBadgeType.pending:
        textColor = AppColors.warningAmber;
        bgColor = AppColors.warningAmber.withValues(alpha: 0.15);
        break;
      case StatusBadgeType.danger:
      case StatusBadgeType.error:
        textColor = AppColors.alertRed;
        bgColor = AppColors.alertRed.withValues(alpha: 0.12);
        break;
      case StatusBadgeType.info:
        textColor = AppColors.gpsBlue;
        bgColor = AppColors.gpsBlue.withValues(alpha: 0.12);
        break;
      case StatusBadgeType.institutional:
        textColor = AppColors.govtBlue;
        bgColor = AppColors.govtBlue.withValues(alpha: 0.12);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: isSmall ? 2.0 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: isSmall ? 12 : 14),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: isSmall
                ? AppTypography.caption.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 11)
                : AppTypography.body.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
