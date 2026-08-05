import 'package:flutter/material.dart';
import '../../models/boundary_alert.dart';
import '../../widgets/common/app_components.dart';
import '../../widgets/portal_frame_scaffold.dart';

/// Module B — Screen #14: Satellite Alert Detail
///
/// Full-detail view of a single BoundaryAlert document.
/// Handles all three tier states including 🟢 green "no change" confirmation.
/// Shows Change Summary, Reliability, NDVI metrics, and demo-data provenance badge.
///
/// Route: /map/alert
/// Arguments: BoundaryAlert (required)
class AlertDetailScreen extends StatelessWidget {
  final BoundaryAlert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(alert.tier.argbColor);
    final isGreen = alert.tier == AlertTier.green;

    return PortalFrameScaffold(
      breadcrumbs: const ['Map', 'Satellite Alert'],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Tier Header Card ──────────────────────────────────────
                _TierHeaderCard(alert: alert, tierColor: tierColor, isGreen: isGreen),
                const SizedBox(height: AppSpacing.lg),

                // ── Demo Data Warning ─────────────────────────────────────
                if (alert.isSyntheticData) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined, color: AppColors.warningAmber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demo Data — Not Field-Verified',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warningAmber,
                                ),
                              ),
                              Text(
                                'Boundary source: ${alert.boundarySource ?? "FALLBACK"} · '
                                'Imagery: ${alert.imagerySource ?? "synthetic"} · '
                                'Model: ${alert.modelVersion ?? "demo-v1-synthetic"}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Parcel Info Card ──────────────────────────────────────
                _SectionCard(
                  title: 'Parcel Information',
                  icon: Icons.terrain_rounded,
                  children: [
                    _InfoRow('Claimant', alert.claimantName ?? 'Unknown'),
                    _InfoRow('Survey No.', '${alert.surveyNo ?? "N/A"}'),
                    _InfoRow('Declared Area', alert.declaredAreaSqm != null
                        ? '${alert.declaredAreaSqm!.toStringAsFixed(0)} m²  '
                          '(${(alert.declaredAreaSqm! / 10000).toStringAsFixed(2)} ha)'
                        : 'N/A'),
                    _InfoRow('Land Use', alert.landUseType ?? 'Unknown'),
                    _InfoRow('Detected', _fmtDate(alert.detectedAt)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Change Summary Card ───────────────────────────────────
                if (!isGreen)
                  _SectionCard(
                    title: 'Change Summary',
                    icon: Icons.compare_arrows_rounded,
                    iconColor: tierColor,
                    children: [
                      _InfoRow(
                        'Area Affected',
                        alert.areaAffectedSqm != null
                            ? '${alert.areaAffectedSqm!.toStringAsFixed(0)} m²'
                            : 'N/A',
                        valueColor: tierColor,
                      ),
                      _InfoRow('Likely Cause',
                        '${alert.likelyCause ?? "Unknown"} (rule-based v1)',
                        note: 'Heuristic classification — not a validated AI classifier',
                      ),
                      _InfoRow('Detection Date', _fmtDate(alert.detectedAt)),
                      if (alert.resolvedAt != null)
                        _InfoRow('Resolved', _fmtDate(alert.resolvedAt!)),
                    ],
                  ),

                if (isGreen)
                  _SectionCard(
                    title: 'Change Analysis',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.successGreen,
                    children: [
                      _InfoRow('Status', 'No change detected', valueColor: AppColors.successGreen),
                      _InfoRow('Likely Cause', alert.likelyCause ?? 'No change detected'),
                      _InfoRow('Analysis Date', _fmtDate(alert.detectedAt)),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),

                // ── Reliability Card ─────────────────────────────────────
                if (alert.resolutionFeasibility != null)
                  _ReliabilityCard(feasibility: alert.resolutionFeasibility!),
                if (alert.resolutionFeasibility != null)
                  const SizedBox(height: AppSpacing.md),

                // ── Satellite Metrics Card ────────────────────────────────
                _SectionCard(
                  title: 'Satellite Metrics',
                  icon: Icons.satellite_alt_rounded,
                  children: [
                    if (alert.ndviMean != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NDVI Index',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.8,
                                  )),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      alert.ndviMean!.toStringAsFixed(2),
                                      style: AppTypography.title.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: _ndviColor(alert.ndviMean!),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(' / 1.0',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ((alert.ndviMean! + 1) / 2).clamp(0.0, 1.0),
                                    backgroundColor: AppColors.divider,
                                    valueColor: AlwaysStoppedAnimation(_ndviColor(alert.ndviMean!)),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          if (alert.confidence != null)
                            Column(
                              children: [
                                Text('Confidence',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.8,
                                  )),
                                const SizedBox(height: 4),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: CircularProgressIndicator(
                                        value: alert.confidence,
                                        strokeWidth: 5,
                                        backgroundColor: AppColors.divider,
                                        valueColor: AlwaysStoppedAnimation(tierColor),
                                      ),
                                    ),
                                    Text(
                                      '${(alert.confidence! * 100).toStringAsFixed(0)}%',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: tierColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Action Button ────────────────────────────────────────
                if (alert.tier != AlertTier.green)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report sent to Forest Rights Committee'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.report_outlined, size: 20),
                      label: const Text('Report to FRC',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tierColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _ndviColor(double ndvi) {
    if (ndvi >= 0.4) return AppColors.successGreen;
    if (ndvi >= 0.2) return AppColors.warningAmber;
    return AppColors.alertRed;
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Tier Header Card ──────────────────────────────────────────────────────────

class _TierHeaderCard extends StatelessWidget {
  final BoundaryAlert alert;
  final Color tierColor;
  final bool isGreen;
  const _TierHeaderCard({required this.alert, required this.tierColor, required this.isGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tierColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tierColor.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(alert.tier.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGreen ? 'Boundary Stable' : alert.tier.displayNameEn,
                  style: AppTypography.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.tier.actionEn,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.forestSage, size: 18),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? note;
  const _InfoRow(this.label, this.value, {this.valueColor, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                if (note != null)
                  Text(note!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reliability Card ──────────────────────────────────────────────────────────

class _ReliabilityCard extends StatelessWidget {
  final ResolutionFeasibility feasibility;
  const _ReliabilityCard({required this.feasibility});

  @override
  Widget build(BuildContext context) {
    final color = feasibility == ResolutionFeasibility.reliable
        ? AppColors.successGreen
        : AppColors.warningAmber;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            feasibility == ResolutionFeasibility.reliable
                ? Icons.verified_outlined
                : Icons.warning_amber_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reliability: ',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        feasibility.label,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  feasibility.explainer,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
