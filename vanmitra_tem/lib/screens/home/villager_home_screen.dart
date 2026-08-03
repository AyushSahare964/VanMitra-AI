import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../models/gram_sabha_meeting.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/village_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/common/app_components.dart';
import '../../widgets/portal_frame_scaffold.dart';
import '../claims/my_claims_screen.dart';
import '../gram_sabha/gram_sabha_dashboard.dart';
import '../profile/profile_screen.dart';
import 'boundary_map_screen.dart';

/// Renovated Villager Home Screen — featuring Forest Canopy identity, Saffron BottomNavBar,
/// GreetingHero, StatTile hierarchy, and completely wired application navigation.
class VillagerHomeScreen extends ConsumerStatefulWidget {
  const VillagerHomeScreen({super.key});

  @override
  ConsumerState<VillagerHomeScreen> createState() => _VillagerHomeScreenState();
}

class _VillagerHomeScreenState extends ConsumerState<VillagerHomeScreen> {
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
        _HomeTab(bottomNavigationBar: navBar, onSwitchTab: (index) => setState(() => _currentTab = index)),
        MyClaimsScreen(bottomNavigationBar: navBar),
        _GramSabhaTab(bottomNavigationBar: navBar),
        _MapTab(bottomNavigationBar: navBar),
        _ProfileTab(bottomNavigationBar: navBar),
      ],
    );
  }
}

/// Home Tab — village overview, next meeting hero, stat metrics & action checklist
class _HomeTab extends ConsumerWidget {
  final Widget bottomNavigationBar;
  final ValueChanged<int>? onSwitchTab;

  const _HomeTab({required this.bottomNavigationBar, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final village = ref.watch(villageProvider);
    
    final villageId = village?.id ?? '';
    final claimsAsync = ref.watch(claimsStreamProvider(villageId));
    final meetingsAsync = ref.watch(meetingsStreamProvider(villageId));

    final approvedClaimsCount = claimsAsync.maybeWhen(
      data: (list) => list.where((c) => c.status.name == 'approved').length.toString(),
      orElse: () => '0',
    );

    final approvedAreaStr = claimsAsync.maybeWhen(
      data: (list) {
        final areaSqM = list
            .where((c) => c.status.name == 'approved')
            .fold<int>(0, (s, c) => s + (c.areaSqMeters?.toInt() ?? 0));
        return (areaSqM / 10000).toStringAsFixed(1);
      },
      orElse: () => '0.0',
    );

    final pastMeetingsCount = meetingsAsync.maybeWhen(
      data: (list) => list.where((m) => m.status.name == 'completed').length.toString(),
      orElse: () => '0',
    );

    final allMeetings = meetingsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <GramSabhaMeeting>[],
    );

    // Identify active today meeting for quick attendance checking
    GramSabhaMeeting? todayMeeting;
    try {
      todayMeeting = allMeetings.firstWhere((m) => m.isToday && m.isAcceptingAttendance);
    } catch (_) {}

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
                // 1. Forest Canopy Greeting Hero
                if (auth.currentUser != null)
                  GreetingHero(
                    userName: auth.currentUser!.name,
                    role: context.tr('villager'),
                    villageName: village?.nameMarathi ?? auth.currentUser!.villageId,
                    onProfileTap: () => onSwitchTab?.call(AppTab.profile.index),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Next Gram Sabha Meeting Announcement Card
                _buildNextMeetingCard(context, allMeetings, todayMeeting),
                const SizedBox(height: AppSpacing.lg),

                // 3. Quantitative Village Metrics (Standardized StatTile Scale)
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: approvedClaimsCount,
                        label: context.tr('approved_claims'),
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        value: approvedAreaStr,
                        label: context.tr('hectares'),
                        icon: Icons.landscape_rounded,
                        iconColor: AppColors.forestSage,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        value: pastMeetingsCount,
                        label: context.tr('meeting_records'),
                        icon: Icons.groups_rounded,
                        iconColor: AppColors.saffron,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // 4. FRA Claims Action Module
                Text(
                  context.tr('claims') /* Claims Management */,
                  style: AppTypography.title.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ActionListItem(
                  icon: Icons.upload_file_rounded,
                  title: context.tr('action_new_claim'),
                  subtitle: context.tr('action_new_claim_sub'),
                  iconColor: AppColors.saffron,
                  onTap: () => Navigator.pushNamed(context, AppRouter.claimType),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.checklist_rtl_rounded,
                  title: context.tr('action_evidence_checklist'),
                  subtitle: context.tr('action_evidence_checklist_sub'),
                  iconColor: AppColors.warningAmber,
                  onTap: () => Navigator.pushNamed(context, AppRouter.rule13Evidence),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 5. Gram Sabha & Governance Actions
                Text(
                  context.tr('gram_sabha') /* Gram Sabha & Records */,
                  style: AppTypography.title.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ActionListItem(
                  icon: Icons.groups_rounded,
                  title: context.tr('action_view_records'),
                  subtitle: context.tr('action_view_records_sub'),
                  iconColor: AppColors.forestSage,
                  onTap: () => onSwitchTab?.call(AppTab.sabha.index),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.how_to_reg_rounded,
                  title: context.tr('action_self_checkin'),
                  subtitle: context.tr('action_self_checkin_sub'),
                  iconColor: AppColors.successGreen,
                  onTap: () {
                    if (todayMeeting != null) {
                      Navigator.pushNamed(context, AppRouter.selfCheckin, arguments: todayMeeting.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('select_active_meeting_first'))),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.map_outlined,
                  title: context.tr('action_map'),
                  subtitle: context.tr('action_map_sub'),
                  iconColor: AppColors.forestCanopy,
                  onTap: () => onSwitchTab?.call(AppTab.map.index),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionListItem(
                  icon: Icons.menu_book_rounded,
                  title: context.tr('action_know_rights'),
                  subtitle: context.tr('action_know_rights_sub'),
                  iconColor: AppColors.womenQuorum,
                  onTap: () => Navigator.pushNamed(context, AppRouter.fraRightsInfo),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMeetingCard(BuildContext context, List<GramSabhaMeeting> allMeetings, GramSabhaMeeting? todayMeeting) {
    final upcoming = allMeetings.where((m) => m.isUpcoming).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    
    final nextMeeting = upcoming.isNotEmpty ? upcoming.first : null;
    final meeting = todayMeeting ?? nextMeeting;

    if (meeting == null) {
      return AppCard(
        elevation: AppElevation.flat,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('next_meeting') /* Next Meeting */,
                    style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    context.tr('no_meeting_scheduled'),
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isToday = todayMeeting != null;

    return AppCard(
      elevation: AppElevation.raised,
      borderColor: isToday ? AppColors.saffron : AppColors.forestSage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: isToday ? AppColors.saffron : AppColors.forestSage,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isToday ? context.tr('todays_meeting') : context.tr('next_meeting'),
                style: AppTypography.subtitle.copyWith(
                  color: isToday ? AppColors.saffron : AppColors.forestSage,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: isToday ? 'ACTIVE NOW' : 'SCHEDULED',
                status: isToday ? StatusType.verified : StatusType.pending,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            meeting.type.displayNameMr,
            style: AppTypography.title.copyWith(fontSize: 17, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${context.tr('venue')}: ${meeting.venue}',
                  style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (isToday) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: context.tr('mark_attendance'),
              icon: Icons.how_to_reg_rounded,
              onPressed: () => Navigator.pushNamed(context, AppRouter.selfCheckin, arguments: meeting.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _GramSabhaTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _GramSabhaTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => GramSabhaDashboard(bottomNavigationBar: bottomNavigationBar);
}

class _MapTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _MapTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => BoundaryMapScreen(bottomNavigationBar: bottomNavigationBar);
}

class _ProfileTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _ProfileTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => ProfileScreen(bottomNavigationBar: bottomNavigationBar);
}
