import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/routes/app_router.dart';
import '../../widgets/van_mitra_app_shell.dart';

/// Profile & Settings Screen
///
/// Design reference: stitch_mahagov_citizen_portal_app/profile_settings/
/// Shows user info, language selection, documents, help, and logout.
class ProfileScreen extends ConsumerWidget {
  final Widget? bottomNavigationBar;
  const ProfileScreen({super.key, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    final userName = auth.currentUser?.name ?? 'Ramesh Pawar';
    final userRole = 'Villager / Claimant';
    final village = auth.currentUser?.villageId ?? 'Ozhar, Palghar';

    final langDisplay = _langLabel(locale.languageCode);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: const VanMitraTopBar(),
      body: Stack(
        children: [
          // ── Government watermark (subtle emblem behind content) ─────────
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.04,
                child: Icon(Icons.account_balance,
                    size: MediaQuery.of(context).size.width * 0.7,
                    color: kOnSurface),
              ),
            ),
          ),

          // ── Scrollable content ──────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header card
                _ProfileHeaderCard(
                  name: userName,
                  role: userRole,
                  location: village,
                ),
                const SizedBox(height: 16),

                // Settings list
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      iconBg: kTertiaryFixed,
                      iconColor: kOnTertiaryFixed,
                      icon: Icons.translate,
                      title: 'Language Selection',
                      subtitle: langDisplay,
                      subtitleColor: kPrimary,
                      onTap: () => _showLanguagePicker(context, ref),
                    ),
                    _SettingsItem(
                      iconBg: kSecondaryFixed,
                      iconColor: kOnSecondaryFixed,
                      icon: Icons.folder_open_outlined,
                      title: 'My Documents',
                      subtitle: 'Filed claims & approved titles',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.myClaims),
                    ),
                    _SettingsItem(
                      iconBg: kErrorContainer,
                      iconColor: const Color(0xFF93000A),
                      icon: Icons.support_agent_outlined,
                      title: 'Help & Legal Aid',
                      subtitle: 'Local NGOs & District Office',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Logout button
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded,
                        color: kOnSurfaceVariant, size: 20),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: kOnSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: kSurfaceContainer,
                      side: const BorderSide(color: kOutlineVariant),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Digital India footer logo (placeholder icon)
                Center(
                  child: Column(
                    children: const [
                      Icon(Icons.phone_android,
                          size: 40, color: kOnSurfaceVariant),
                      SizedBox(height: 4),
                      Text(
                        'Digital India',
                        style: TextStyle(
                          fontSize: 11,
                          color: kOnSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar ??
          const VanMitraBottomNav(activeTab: VanMitraTab.profile),
    );
  }

  String _langLabel(String code) {
    const map = {
      'mr': 'मराठी (Marathi)',
      'hi': 'हिंदी (Hindi)',
      'en': 'English',
      'kn': 'ಕನ್ನಡ (Kannada)',
    };
    return map[code] ?? 'मराठी (Marathi)';
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kOnSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('मराठी', 'mr'),
              ('हिंदी', 'hi'),
              ('English', 'en'),
              ('ಕನ್ನಡ', 'kn'),
            ].map((pair) {
              return ListTile(
                title: Text(pair.$1,
                    style: const TextStyle(fontSize: 16, color: kOnSurface)),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(pair.$2);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: kOnSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.splash,
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kStatusError),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final String location;

  const _ProfileHeaderCard({
    required this.name,
    required this.role,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: kOutlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryContainer, width: 2),
              color: kSurfaceContainer,
            ),
            child: ClipOval(
              child: Icon(Icons.person, size: 50, color: kOnSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 16, color: kOnSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(role,
                        style: const TextStyle(
                            fontSize: 14, color: kOnSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: kOnSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 14, color: kOnSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: kOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(height: 1, color: Color(0x1ABECAB5)),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor ?? kOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
