import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';

// ── Design Tokens (from DESIGN.md) ─────────────────────────────────────────
const kPrimary = Color(0xFF056C00);
const kPrimaryContainer = Color(0xFF138808);
const kOnPrimary = Color(0xFFFFFFFF);
const kOnPrimaryContainer = Color(0xFFFBFFF3);
const kSurface = Color(0xFFF8F9FA);
const kSurfaceWhite = Color(0xFFFFFFFF);
const kSurfaceContainerHighest = Color(0xFFE1E3E4);
const kSurfaceContainerHigh = Color(0xFFE7E8E9);
const kSurfaceContainerLow = Color(0xFFF3F4F5);
const kSurfaceContainer = Color(0xFFEDEEEF);
const kOnSurface = Color(0xFF191C1D);
const kOnSurfaceVariant = Color(0xFF3F4A3A);
const kOutlineVariant = Color(0xFFBECAB5);
const kStatusSuccess = Color(0xFF138808);
const kStatusWarning = Color(0xFFFFB800);
const kStatusError = Color(0xFFD32F2F);
const kErrorContainer = Color(0xFFFFDAD6);
const kSecondaryContainer = Color(0xFFFE9832);
const kOnSecondaryContainer = Color(0xFF683700);
const kTertiaryFixed = Color(0xFFE0E0FF);
const kOnTertiaryFixed = Color(0xFF00006E);
const kSecondaryFixed = Color(0xFFFFDCC2);
const kOnSecondaryFixed = Color(0xFF2E1500);
const kPrimaryFixedDim = Color(0xFF72DE5C);

/// Which bottom-nav tab is active on this screen.
enum VanMitraTab { home, claims, map, ledger, profile }

// ── Top App Bar ─────────────────────────────────────────────────────────────

/// Shared header: [🏛 account_balance] VanMitra-AI [🌐 language]
/// Matches the design reference across all 3 screens.
class VanMitraTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;

  const VanMitraTopBar({super.key, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              // Left: emblem or back
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: kPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(Icons.account_balance, color: kPrimary, size: 24),
                  ),
                ),

              // Center: title
              const Expanded(
                child: Text(
                  'VanMitra-AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),

              // Right: language icon
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.language, color: kPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────────

/// Shared bottom navigation bar: Home | Claims | Map | Ledger | Profile
/// Active tab shows a green pill background (primary-container style).
class VanMitraBottomNav extends StatelessWidget {
  final VanMitraTab activeTab;

  const VanMitraBottomNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Home',
                isActive: activeTab == VanMitraTab.home,
                onTap: () => _go(context, AppRouter.villagerHome),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                activeIcon: Icons.description,
                label: 'Claims',
                isActive: activeTab == VanMitraTab.claims,
                onTap: () => _go(context, AppRouter.myClaims),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Map',
                isActive: activeTab == VanMitraTab.map,
                onTap: () => _go(context, AppRouter.boundaryMap),
              ),
              _NavItem(
                icon: Icons.history_edu_outlined,
                activeIcon: Icons.history_edu,
                label: 'Ledger',
                isActive: activeTab == VanMitraTab.ledger,
                onTap: () => _go(context, AppRouter.resolutionLedger),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: activeTab == VanMitraTab.profile,
                onTap: () => _go(context, AppRouter.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: kPrimaryContainer,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? kOnPrimaryContainer : kOnSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                    isActive ? kOnPrimaryContainer : kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
