import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../services/localization_service.dart';
import '../../models/claim.dart';
import '../../providers/claims_provider.dart';
import '../../widgets/portal_frame_scaffold.dart';
import '../../widgets/status_timeline_widget.dart';

/// My Claims List — DBT-style application tiles with status badges.
///
/// Features:
/// - Acknowledgement number search bar (mirrors DBT's "Track Application")
/// - Status filter chips
/// - Per-claim status tile with color-coded badge
/// - 60-day appeal countdown chip for rejected claims
class MyClaimsScreen extends ConsumerStatefulWidget {
  final Widget? bottomNavigationBar;
  const MyClaimsScreen({super.key, this.bottomNavigationBar});

  @override
  ConsumerState<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends ConsumerState<MyClaimsScreen> {
  final _searchCtrl = TextEditingController();
  ClaimStatus? _filterStatus;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX (Problem 3): Watch the filtered Firestore stream instead of Hive
    // to enforce per-user data isolation — villagers cannot see each other's claims.
    final claimsAsync = ref.watch(userClaimsStreamProvider);

    // Show spinner while Firestore stream is initializing
    if (claimsAsync.isLoading) {
      return PortalFrameScaffold(
        breadcrumbs: [context.tr('tab_dashboard'), context.tr('title_my_claims')],
        bottomNavigationBar: widget.bottomNavigationBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show a friendly error card instead of a blank screen
    if (claimsAsync.hasError) {
      return PortalFrameScaffold(
        breadcrumbs: [context.tr('tab_dashboard'), context.tr('title_my_claims')],
        bottomNavigationBar: widget.bottomNavigationBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 12),
                Text(
                  context.tr('error_loading_claims'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allClaims = claimsAsync.value ?? [];

    // Apply search + filter
    var filtered = allClaims.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.claimantName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter =
          _filterStatus == null || c.status == _filterStatus;
      return matchSearch && matchFilter;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return PortalFrameScaffold(
      breadcrumbs: [context.tr('tab_dashboard'), context.tr('title_my_claims')],
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.claimType),
        backgroundColor: AppColors.accentSaffron,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('action_new_claim'),
          style: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar (DBT "Track Application" pattern) ─────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari', fontSize: 13),
              decoration: InputDecoration(
                hintText: context.tr('search_claim_hint'),
                hintStyle: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.govtBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                      color: AppColors.govtBlue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // ── Status filter chips ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: context.tr('filter_all'),
                    selected: _filterStatus == null,
                    onTap: () =>
                        setState(() => _filterStatus = null),
                    color: AppColors.govtBlue,
                  ),
                  const SizedBox(width: 8),
                  for (final s in ClaimStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: s.getLocalizedStatus(context),
                        selected: _filterStatus == s,
                        onTap: () =>
                            setState(() => _filterStatus = s),
                        color: _statusColor(s),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Summary stats ────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatPill(
                  '${allClaims.where((c) => c.status == ClaimStatus.approved).length}',
                  context.tr('filter_approved'),
                  AppColors.successGreen,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  '${allClaims.where((c) => c.status == ClaimStatus.underReview || c.status == ClaimStatus.submitted).length}',
                  context.tr('filter_pending'),
                  AppColors.warningAmber,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  '${allClaims.where((c) => c.status == ClaimStatus.rejected).length}',
                  context.tr('filter_rejected'),
                  AppColors.alertRed,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} ${context.tr('claims_count_suffix')}',
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Claims list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    hasFilter: _filterStatus != null || _searchQuery.isNotEmpty,
                    onNewClaim: () =>
                        Navigator.pushNamed(context, AppRouter.claimType),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) =>
                        _ClaimTile(claim: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.approved:
        return AppColors.successGreen;
      case ClaimStatus.rejected:
        return AppColors.alertRed;
      case ClaimStatus.underReview:
      case ClaimStatus.submitted:
        return AppColors.warningAmber;
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? color : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            fontSize: 11,
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  const _StatPill(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final Claim claim;
  const _ClaimTile({required this.claim});

  Color _statusColor() {
    switch (claim.status) {
      case ClaimStatus.approved:
        return AppColors.successGreen;
      case ClaimStatus.rejected:
        return AppColors.alertRed;
      case ClaimStatus.underReview:
      case ClaimStatus.submitted:
        return AppColors.warningAmber;
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final isRejected = claim.status == ClaimStatus.rejected;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.claimForm, // → tracking screen in future
        arguments: claim.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        color: isRejected
            ? AppColors.alertRed.withOpacity(0.02)
            : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rejected claim banner
            if (isRejected && claim.isAppealWindowOpen)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColors.alertRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.alertRed, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${context.tr('appeal_deadline')}: ${claim.appealDaysRemaining} ${context.tr('days_left')}',
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 11,
                        color: AppColors.alertRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.rejectionCheck,
                        arguments: claim.id,
                      ),
                      child: Text(
                        context.tr('appeal_now'),
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 11,
                          color: AppColors.alertRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor().withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(claim.status.icon,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),

                // Claim info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              claim.claimantName,
                              style: const TextStyle(
                                fontFamily: 'NotoSansDevanagari',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      _statusColor().withOpacity(0.4)),
                            ),
                            child: Text(
                              claim.status.displayNameMr,
                              style: TextStyle(
                                fontFamily: 'NotoSansDevanagari',
                                fontSize: 10,
                                color: _statusColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('application_no')} ${claim.id.substring(0, 12)}…',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '${context.tr('survey_no')}: ${claim.surveyNumber ?? "N/A"}  •  ${claim.areaSqMeters?.toStringAsFixed(0) ?? "?"} ${context.tr('sq_meters')}',
                        style: const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${context.tr('date_prefix')}: ${fmt.format(claim.createdAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),

            // Mini status timeline for non-draft claims
            if (claim.status != ClaimStatus.draft) ...[
              const SizedBox(height: 10),
              StatusTimelineWidget(
                steps: [
                  context.tr('step_received'),
                  context.tr('step_verification'),
                  context.tr('step_gramsabha'),
                  context.tr('step_decision'),
                ],
                currentStep: _timelineStep(),
                isRejected: claim.status == ClaimStatus.rejected,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _timelineStep() {
    switch (claim.status) {
      case ClaimStatus.submitted:
        return 0;
      case ClaimStatus.underReview:
        return 1;
      case ClaimStatus.appealFiled:
        return 2;
      case ClaimStatus.approved:
        return 3;
      case ClaimStatus.rejected:
        return 3;
      default:
        return 0;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onNewClaim;
  const _EmptyState({required this.hasFilter, required this.onNewClaim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? context.tr('no_claims_filter')
                  : context.tr('no_claims_yet'),
              style: const TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 15,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onNewClaim,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  context.tr('action_new_claim'),
                  style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentSaffron,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
