import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/village_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/notices_provider.dart';
import '../../models/notice.dart';
import '../../services/localization_service.dart';
import '../../core/routes/app_router.dart';
import '../gram_sabha/gram_sabha_dashboard.dart';
import '../claims/my_claims_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/portal_frame_scaffold.dart';

/// Admin Home Screen — full Gram Sabha management
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'डॅशबोर्ड'),
        BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'दावे'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'ग्रामसभा'),
        BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'नकाशा'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'प्रोफाइल'),
      ],
    );

    return IndexedStack(
      index: _currentTab,
      children: [
        _AdminDashboard(bottomNavigationBar: bottomNavBar),
        MyClaimsScreen(bottomNavigationBar: bottomNavBar), // Reuse full claims screen
        _AdminGramSabhaTab(bottomNavigationBar: bottomNavBar),
        _AdminMapTab(bottomNavigationBar: bottomNavBar),
        _AdminProfileTab(bottomNavigationBar: bottomNavBar),
      ],
    );
  }
}

class _AdminDashboard extends ConsumerWidget {
  final Widget bottomNavigationBar;
  const _AdminDashboard({required this.bottomNavigationBar});

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
      orElse: () => '-',
    );
    
    final totalMeetings = meetingsAsync.maybeWhen(
      data: (list) => list.where((m) => m.status.name == 'completed').length.toString(),
      orElse: () => '-',
    );

    return PortalFrameScaffold(
      breadcrumbs: const [], // No breadcrumbs on dashboard
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
              // Admin welcome
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2444), AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppColors.secondary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('welcome')}, ${auth.currentUser?.name ?? "Admin"}',
                            style: const TextStyle(
                              fontFamily: 'NotoSansDevanagari',
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${context.tr('admin_subtitle')} • ${village?.nameMarathi ?? "ओझर"}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _AdminStat(value: totalClaims, label: context.tr('total_claims'), icon: Icons.description, color: AppColors.primary),
                  const SizedBox(width: 10),
                  _AdminStat(value: totalMeetings, label: context.tr('meetings'), icon: Icons.groups, color: AppColors.success),
                  const SizedBox(width: 10),
                  _AdminStat(value: '${resolutions.length}', label: context.tr('resolutions'), icon: Icons.gavel, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  _AdminStat(value: '${village?.registeredAdultMembers ?? 500}', label: context.tr('members'), icon: Icons.people, color: AppColors.womenQuorum),
                ],
              ),
              const SizedBox(height: 24),

              // Admin Actions
              const Text('Admin Actions', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              _AdminActionCard(
                icon: Icons.add_circle,
                title: context.tr('action_schedule_meeting'),
                subtitle: 'Schedule New Gram Sabha Meeting',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.createMeeting);
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.campaign,
                title: context.tr('action_post_notice'),
                subtitle: 'Post Notice to Village Notice Board',
                color: AppColors.govtBlue,
                onTap: () async {
                  // FIX (Problem 10): Actual notice write replaces "Coming Soon"
                  await ref.read(noticesProvider.notifier).postAdminNotice(
                    titleMr: 'महत्त्वाची सूचना: ग्रामसभा',
                    titleEn: 'Important Notice: Gram Sabha',
                    bodyMr: 'पुढील आठवड्यात विशेष ग्रामसभेचे आयोजन केले आहे.',
                    bodyEn: 'A special Gram Sabha is scheduled for next week.',
                    category: NoticeCategory.general,
                    severity: NoticeSeverity.info,
                    validUntil: DateTime.now().add(const Duration(days: 14)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notice posted to board!')),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.how_to_reg,
                title: context.tr('action_attendance'),
                subtitle: 'Manage Attendance & Quorum Dashboard',
                color: AppColors.success,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('select_active_meeting_first'))));
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.gavel,
                title: context.tr('action_record_resolution'),
                subtitle: 'Record Resolution & Publish to Ledger',
                color: AppColors.primary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('select_active_meeting_first'))));
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.verified,
                title: context.tr('action_verify_chain'),
                subtitle: 'Verify Resolution Ledger Chain Integrity',
                color: AppColors.stRepresentation,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chain Verification is in the Ledger Screen.')));
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.fact_check,
                title: context.tr('action_review_claims'),
                subtitle: 'Review & Approve Pending Claims',
                color: AppColors.warning,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
                },
              ),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.map,
                title: context.tr('action_map_monitor'),
                subtitle: 'Boundary Map & Alert Monitoring',
                color: AppColors.pvtgRepresentation,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
                },
              ),
              const SizedBox(height: 24),

              // Village info card
              if (village != null) ...[
                const Text('Village Overview', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _InfoRow('गाव / Village', '${village.nameMarathi} (${village.nameEnglish})'),
                      _InfoRow('तालुका / Taluka', '${village.talukaMarathi} (${village.talukaEnglish})'),
                      _InfoRow('जिल्हा / District', '${village.districtMarathi} (${village.districtEnglish})'),
                      _InfoRow('लोकसंख्या / Population', '~${village.totalPopulation}'),
                      _InfoRow('नोंदणीकृत सदस्य / Members', '${village.registeredAdultMembers}'),
                      _InfoRow('महिला सदस्य / Women', '${village.registeredWomenMembers}'),
                      _InfoRow('ST / अनुसूचित जमाती', '${(village.stPercentage * 100).toStringAsFixed(0)}%'),
                      _InfoRow('मंजूर दावे / Approved Claims', '${village.totalApprovedClaims}'),
                      _InfoRow('एकूण क्षेत्र / Total Area', '${village.totalApprovedAreaHectares.toStringAsFixed(1)} hectares'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(value, style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _AdminStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 9, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  State<_AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<_AdminActionCard> with SingleTickerProviderStateMixin {
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
            color: Colors.white, borderRadius: BorderRadius.circular(12),
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
                width: 42, height: 42,
                decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// _AdminClaimsTab removed since we use MyClaimsScreen directly

class _AdminGramSabhaTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminGramSabhaTab({required this.bottomNavigationBar});
  @override
  Widget build(BuildContext context) =>
      GramSabhaDashboard(bottomNavigationBar: bottomNavigationBar);
}

class _AdminMapTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminMapTab({required this.bottomNavigationBar});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('सीमा नकाशा')), bottomNavigationBar: bottomNavigationBar, body: const Center(child: Text('Boundary Map — Coming soon')));
}

class _AdminProfileTab extends StatelessWidget {
  final Widget bottomNavigationBar;
  const _AdminProfileTab({required this.bottomNavigationBar});
  @override
  Widget build(BuildContext context) =>
      ProfileScreen(bottomNavigationBar: bottomNavigationBar);
}
