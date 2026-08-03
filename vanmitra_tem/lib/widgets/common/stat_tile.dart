import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum StatTileType {
  claims,
  meetings,
  resolutions,
  members,
  custom,
}

/// Unified KPI StatTile with semantic icon background colors, compact padding, and zero-overflow layout.
class StatTile extends StatelessWidget {
  final StatTileType type;
  final String label;
  final String value;
  final IconData icon;
  final Color? customIconColor;
  final Color? iconColor;
  final Color? customBackgroundColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    this.type = StatTileType.custom,
    required this.label,
    required this.value,
    required this.icon,
    this.customIconColor,
    this.iconColor,
    this.customBackgroundColor,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color activeIconColor;
    Color iconBgColor;

    if (iconColor != null) {
      activeIconColor = iconColor!;
      iconBgColor = customBackgroundColor ?? iconColor!.withValues(alpha: 0.12);
    } else {
      switch (type) {
        case StatTileType.claims:
          activeIconColor = AppColors.forestCanopy;
          iconBgColor = AppColors.forestCanopy.withValues(alpha: 0.1);
          break;
        case StatTileType.meetings:
          activeIconColor = AppColors.successGreen;
          iconBgColor = AppColors.successGreen.withValues(alpha: 0.12);
          break;
        case StatTileType.resolutions:
          activeIconColor = AppColors.saffron;
          iconBgColor = AppColors.saffron.withValues(alpha: 0.15);
          break;
        case StatTileType.members:
          activeIconColor = AppColors.womenPurple;
          iconBgColor = AppColors.womenPurple.withValues(alpha: 0.12);
          break;
        case StatTileType.custom:
          activeIconColor = customIconColor ?? AppColors.forestCanopy;
          iconBgColor = customBackgroundColor ?? activeIconColor.withValues(alpha: 0.1);
          break;
      }
    }

    final displayValue = (value == '-' || (value.isEmpty && !isLoading)) ? '0' : value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: activeIconColor, size: 20),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (isLoading)
                Container(
                  height: 22,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayValue,
                    style: AppTypography.stat.copyWith(fontSize: 22, height: 1.1),
                    maxLines: 1,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
