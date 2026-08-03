import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../models/notice.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/notices_provider.dart';
import '../../providers/village_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/common/app_components.dart';
import '../../widgets/portal_frame_scaffold.dart';
import '../claims/my_claims_screen.dart';
import '../gram_sabha/gram_sabha_dashboard.dart';
import '../profile/profile_screen.dart';
import 'boundary_map_screen.dart';

/// Renovated Admin Home Screen — authoritative governance dashboard built on Forest Canopy tokens,
/// Saffron navigation, StatTile diagnostic metrics, and seamless action linkages.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final navBar = BottomNavBar(
      currentTab: AppTab.values[_currentTab],
      onTabSelected: (tab) => setState(() => _currentTab = tab.index),
    );

    return IndexedStack(
      index: _currentTab,
      children: [
        _AdminDashboard(bottomNavigationBar: navBar, onSwitchTab: (index) => setState(() => _currentTab = index)),
        MyClaimsScreen(bottomNavigationBar: navBar),
        _AdminGramSabhaTab(bottomNavigationBar: navBar),
        _AdminMapTab(bottomNavigationBar: navBar),
        _AdminProfileTab(bottomNavigationBar: navBar),
      ],
    );
  }
}

class _AdminDashboard extends ConsumerWidget {
  final Widget bottomNavigationBar;
  final ValueChanged<int>? onSwitchTab;

  const _AdminDashboard({required this.bottomNavigationBar, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final village = ref.watch(villageProvider);
    final resolutions = ref.watch(resolutionProvider);
    
    final villageId = village?.id ?? '';
    final claimsAsync = ref.watch(claimsStreamProvider(villageId));
    final meetingsAsync = ref.watch(meetingsStreamProvider(villageId));

    final totalClaims = claimsAsync.maybeWhen(
      data: (list) => list.length.toString(),
      orElse: () => '0',
    );
    
    final totalMeetings = meetingsAsync.maybeWhen(
      data: (list) => list.where((m) => m.status.name == 'completed').length.toString(),
      orElse: () => '0',
    );

    return PortalFrameScaffold(
      breadcrumbs: const [],
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Governance Greeting Hero
                GreetingHero(
                  userName: auth.currentUser?.name ?? "Admin Officer",
                  role: "FRC Admin • Gram Sabha Secretary",
                  villageName: village?.nameMarathi ?? "ओझर ग्रा.पं.",
                  onProfileTap: () => onSwitchTab?.call(AppTab.profile.index),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. High-Density Diagnostic Stat Tiles
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.15,
                  children: [
                    StatTile(
                      value: totalClaims,
                      label: context.tr('total_claims') /* Total Claims */,
                      icon: Icons.description_rounded,
                      iconColor: AppColors.saffron,
                    ),
                    StatTile(
                      value: totalMeetings,
                      label: context.tr('meetings') /* Completed Meetings */,
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.successGreen,
                    ),
                    StatTile(
                      value: '${resolutions.length}',
                      label: context.tr('resolutions') /* Adopted Resolutions */,
                      icon: Icons.gavel_rounded,
                      iconColor: AppColors.govtBlue,
                    ),
                    StatTile(
                      value: '${village?.registeredAdultMembers ?? 500}',
                      label: context.tr('members') /* Registered Citizens */,
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.forestSage,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // 3. Administrative Operations Suite
                Text(
                  'Admin Governance Operations',
                  style: AppTypography.title.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ActionListItem(
                  icon: Icons.add_circle_outline_rounded,
                  title: context.tr('action_schedule_meeting'),
                  subtitle: 'Schedule New Gram Sabha & Define Agenda',
                  iconColor: AppColors.saffron,
                  onTap: () => Navigator.pushNamed(context, AppRouter.createMeeting),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.campaign_rounded,
                  title: context.tr('action_post_notice'),
                  subtitle: 'Broadcast High-Priority Notice to Village Board',
                  iconColor: AppColors.govtBlue,
                  onTap: () async {
                    await ref.read(noticesProvider.notifier).postAdminNotice(
                      titleMr: 'महत्त्वाची सूचना: विशेष ग्रामसभा',
                      titleEn: 'Important Notice: Special Gram Sabha',
                      bodyMr: 'पुढील आठवड्यात वन हक्क दाव्यांच्या मंजुरीसाठी विशेष बैठक होणार आहे.',
                      bodyEn: 'A special Gram Sabha is scheduled next week for FRA claim validation.',
                      category: NoticeCategory.general,
                      severity: NoticeSeverity.info,
                      validUntil: DateTime.now().add(const Duration(days: 14)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notice broadcasted to village board!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.fact_check_rounded,
                  title: context.tr('action_review_claims') /* Review Claims */,
                  subtitle: 'Inspect Evidence & Adjudicate Pending FRA Claims',
                  iconColor: AppColors.warningAmber,
                  onTap: () => onSwitchTab?.call(AppTab.claims.index),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.how_to_reg_rounded,
                  title: context.tr('action_attendance'),
                  subtitle: 'Manage Attendance & Quorum Verification Dashboard',
                  iconColor: AppColors.successGreen,
                  onTap: () => onSwitchTab?.call(AppTab.sabha.index),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.gavel_rounded,
                  title: context.tr('action_record_resolution'),
                  subtitle: 'Record Official Resolution & Publish to Ledger',
                  iconColor: AppColors.forestSage,
                  onTap: () => onSwitchTab?.call(AppTab.sabha.index),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.map_rounded,
                  title: context.tr('action_map_monitor') /* Boundary Map Monitor */,
                  subtitle: 'CFR Boundary Map & encroachment Alert Monitoring',
                  iconColor: AppColors.forestCanopy,
                  onTap: () => onSwitchTab?.call(AppTab.map.index),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 4. Detailed Village Census & Area Card
                if (village != null) ...[
                  Text(
                    'Village Census & FRA Domain Summary',
                    style: AppTypography.title.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    elevation: AppElevation.flat,
                    child: Column(
                      children: [
                        _InfoRow('गाव / Village Name', '${village.nameMarathi} (${village.nameEnglish})'),
                        _InfoRow('तालुका / Taluka', '${village.talukaMarathi} (${village.talukaEnglish})'),
                        _InfoRow('जिल्हा / District', '${village.districtMarathi} (${village.districtEnglish})'),
                        _InfoRow('लोकसंख्या / Census Population', '~${village.totalPopulation}'),
                        _InfoRow('नोंदणीकृत सदस्य / Adult Members', '${village.registeredAdultMembers}'),
                        _InfoRow('महिला सदस्य / Women Members', '${village.registeredWomenMembers}'),
                        _InfoRow('ST / Tribal Demographic', '${(village.stPercentage * 100).toStringAsFixed(0)}%'),
                        _InfoRow('मंजूर दावे / Approved Claims', '${village.totalApprovedClaims}'),
                        _InfoRow('एकूण क्षेत्र / Confirmed Domain', '${village.totalApprovedAreaHectares.toStringAsFixed(1)} Hectares'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: AppTypography.subtitle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AdminGramSabhaTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminGramSabhaTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => GramSabhaDashboard(bottomNavigationBar: bottomNavigationBar);
}

class _AdminMapTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminMapTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => BoundaryMapScreen(bottomNavigationBar: bottomNavigationBar);
}

class _AdminProfileTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminProfileTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => ProfileScreen(bottomNavigationBar: bottomNavigationBar);
}
