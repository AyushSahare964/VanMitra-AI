import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Unified card primitive replacing inconsistent stat cards, action rows, and dashboard tiles.
class AppCard extends StatelessWidget {
  final Widget child;
  final AppElevation elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.elevation = AppElevation.raised,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: elevation.shadow,
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.2) : elevation.border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
