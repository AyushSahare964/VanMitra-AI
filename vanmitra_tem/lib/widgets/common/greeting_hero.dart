import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Replaces flat navy greeting card with an elevated Forest Canopy to Sage gradient card.
class GreetingHero extends StatelessWidget {
  final String userName;
  final String role;
  final String villageName;
  final VoidCallback? onProfileTap;

  const GreetingHero({
    super.key,
    required this.userName,
    required this.role,
    required this.villageName,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isEmpty ? 'VanMitra Citizen' : userName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forestCanopy, AppColors.forestSage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B241A),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.saffron,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : 'V',
                  style: AppTypography.display.copyWith(
                    color: AppColors.textOnBrand,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, $displayName',
                  style: AppTypography.display.copyWith(
                    color: AppColors.textOnBrand,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnBrand,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (villageName.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.forestMist, size: 12),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              villageName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.forestMist,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.spa_rounded,
            color: AppColors.forestMist,
            size: 28,
          ),
        ],
      ),
    );
  }
}
