import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/notice.dart';

/// Reusable notice ticker supporting severity coloring (info/warning/critical) and dismissibility.
class NoticeTicker extends StatefulWidget {
  final String title;
  final String? subtitle;
  final NoticeSeverity severity;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const NoticeTicker({
    super.key,
    required this.title,
    this.subtitle,
    this.severity = NoticeSeverity.info,
    this.onDismiss,
    this.isDismissible = true,
  });

  factory NoticeTicker.fromNotice(Notice notice, {VoidCallback? onDismiss, String lang = 'en'}) {
    return NoticeTicker(
      title: notice.titleFor(lang),
      subtitle: notice.bodyFor(lang),
      severity: notice.severity,
      onDismiss: onDismiss,
    );
  }

  @override
  State<NoticeTicker> createState() => _NoticeTickerState();
}

class _NoticeTickerState extends State<NoticeTicker> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (widget.severity) {
      case NoticeSeverity.info:
        bgColor = AppColors.gpsBlue.withValues(alpha: 0.1);
        borderColor = AppColors.gpsBlue.withValues(alpha: 0.3);
        iconColor = AppColors.govtBlue;
        icon = Icons.campaign_rounded;
        break;
      case NoticeSeverity.warning:
        bgColor = AppColors.warningAmber.withValues(alpha: 0.15);
        borderColor = AppColors.warningAmber.withValues(alpha: 0.4);
        iconColor = AppColors.secondaryDark;
        icon = Icons.error_outline_rounded;
        break;
      case NoticeSeverity.critical:
        bgColor = AppColors.alertRed.withValues(alpha: 0.12);
        borderColor = AppColors.alertRed.withValues(alpha: 0.4);
        iconColor = AppColors.alertRed;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.isDismissible) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                setState(() => _dismissed = true);
                if (widget.onDismiss != null) widget.onDismiss!();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
