import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/village_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../models/gram_sabha_meeting.dart';
import '../../core/routes/app_router.dart';
import '../../services/localization_service.dart';
import '../gram_sabha/gram_sabha_dashboard.dart';
import '../claims/my_claims_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/portal_frame_scaffold.dart';

/// Villager Home Screen — Gram Sabha features prominent
class VillagerHomeScreen extends ConsumerStatefulWidget {
  const VillagerHomeScreen({super.key});

  @override
  ConsumerState<VillagerHomeScreen> createState() => _VillagerHomeScreenState();
}

class _VillagerHomeScreenState extends ConsumerState<VillagerHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final bottomNavBar = BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
      selectedItemColor: AppColors.govtBlue,
      unselectedItemColor: const Color(0xFF94A3B8),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: context.tr('tab_dashboard')),
        BottomNavigationBarItem(icon: const Icon(Icons.description_rounded), label: context.tr('tab_claims')),
        BottomNavigationBarItem(icon: const Icon(Icons.groups_rounded), label: context.tr('tab_gramsabha')),
        BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: context.tr('tab_map')),
        BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: context.tr('tab_profile')),
      ],
    );

    return IndexedStack(
      index: _currentTab,
      children: [
        _HomeTab(bottomNavigationBar: bottomNavBar),
        MyClaimsScreen(bottomNavigationBar: bottomNavBar),
        _GramSabhaTab(bottomNavigationBar: bottomNavBar),
        _MapTab(bottomNavigationBar: bottomNavBar),
        _ProfileTab(bottomNavigationBar: bottomNavBar),
      ],
    );
  }
}

/// Home Tab — village overview + next meeting + quick actions
class _HomeTab extends ConsumerWidget {
  final Widget bottomNavigationBar;
  const _HomeTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final village = ref.watch(villageProvider);
    
    final villageId = village?.id ?? '';
    final claimsAsync = ref.watch(claimsStreamProvider(villageId));
    final meetingsAsync = ref.watch(meetingsStreamProvider(villageId));

    final approvedClaimsCount = claimsAsync.maybeWhen(
      data: (list) => list.where((c) => c.status.name == 'approved').length.toString(),
      orElse: () => '-',
    );

    final approvedAreaStr = claimsAsync.maybeWhen(
      data: (list) {
        final areaSqM = list
            .where((c) => c.status.name == 'approved')
            .fold<int>(0, (s, c) => s + (c.areaSqMeters?.toInt() ?? 0));
        return (areaSqM / 10000).toStringAsFixed(1);
      },
      orElse: () => '-',
    );

    final pastMeetingsCount = meetingsAsync.maybeWhen(
      data: (list) => list.where((m) => m.status.name == 'completed').length.toString(),
      orElse: () => '-',
    );
    
    final allMeetings = meetingsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <GramSabhaMeeting>[],
    );

    return PortalFrameScaffold(
      breadcrumbs: const [], // No breadcrumbs on home
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
              // Welcome card
              if (auth.currentUser != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          auth.currentUser!.name.isNotEmpty
                              ? auth.currentUser!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${context.tr('welcome')}, ${auth.currentUser!.name}',
                              style: const TextStyle(
                                fontFamily: 'NotoSansDevanagari',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${context.tr('villager')} • ${village?.nameMarathi ?? 'ओझर'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Next Gram Sabha card
              _buildNextMeetingCard(context, allMeetings),
              const SizedBox(height: 16),

              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      value: approvedClaimsCount,
                      label: context.tr('approved_claims'),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.landscape,
                      value: approvedAreaStr,
                      label: context.tr('hectares'),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.groups,
                      value: pastMeetingsCount,
                      label: context.tr('meeting_records'),
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Claims Actions
              Text(context.tr('claims'), style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.upload_file,
                title: context.tr('action_new_claim'),
                subtitle: context.tr('action_new_claim_sub'),
                color: AppColors.secondary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.checklist_rtl,
                title: context.tr('action_evidence_checklist'),
                subtitle: context.tr('action_evidence_checklist_sub'),
                color: AppColors.warning,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.rule13Evidence);
                },
              ),
              const SizedBox(height: 24),

              // Gram sabha actions
              Text(context.tr('gram_sabha'), style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.groups,
                title: context.tr('action_view_records'),
                subtitle: context.tr('action_view_records_sub'),
                color: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.gramSabhaDashboard);
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.how_to_reg,
                title: context.tr('action_self_checkin'),
                subtitle: context.tr('action_self_checkin_sub'),
                color: AppColors.success,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('select_active_meeting_first'))));
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.map_outlined,
                title: context.tr('action_map'),
                subtitle: context.tr('action_map_sub'),
                color: AppColors.success,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.menu_book_outlined,
                title: context.tr('action_know_rights'),
                subtitle: context.tr('action_know_rights_sub'),
                color: AppColors.womenQuorum,
                onTap: () {},
              ),
            ]),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildNextMeetingCard(BuildContext context, List<GramSabhaMeeting> allMeetings) {
    GramSabhaMeeting? todayMeeting;
    try {
      todayMeeting = allMeetings.firstWhere((m) => m.isToday && m.isAcceptingAttendance);
    } catch (_) {}

    final upcoming = allMeetings.where((m) => m.isUpcoming).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    
    final nextMeeting = upcoming.isNotEmpty ? upcoming.first : null;
    final meeting = todayMeeting ?? nextMeeting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: meeting != null ? AppColors.secondaryLight.withOpacity(0.15) : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: meeting != null ? AppColors.secondary : AppColors.divider,
          width: meeting != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: meeting != null ? AppColors.secondary : AppColors.textTertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                todayMeeting != null ? context.tr('todays_meeting') : context.tr('next_meeting'),
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: meeting != null ? AppColors.secondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (meeting != null) ...[
            Text(
              '${meeting.type.displayNameMr}',
              style: const TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('venue')}: ${meeting.venue}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (todayMeeting != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.how_to_reg, size: 18),
                  label: Text(context.tr('mark_attendance')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
              ),
          ] else
            Text(
              context.tr('no_meeting_scheduled'),
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Gram Sabha Tab — passes bottomNavigationBar directly into dashboard to avoid
/// nested Scaffold (GramSabhaDashboard already returns its own Scaffold).
class _GramSabhaTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _GramSabhaTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    return GramSabhaDashboard(bottomNavigationBar: bottomNavigationBar);
  }
}

/// Map Tab (placeholder)
class _MapTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _MapTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(context.tr('tab_map'))), bottomNavigationBar: bottomNavigationBar, body: Center(child: Text(context.tr('coming_soon'))));
}

/// Profile Tab — embeds the real ProfileScreen with the shared bottom nav.
class _ProfileTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _ProfileTab({required this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(bottomNavigationBar: bottomNavigationBar);
  }
}

/// Small stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isPressed ? 0.05 : 0.08),
                blurRadius: _isPressed ? 2 : 8,
                offset: Offset(0, _isPressed ? 1 : 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
