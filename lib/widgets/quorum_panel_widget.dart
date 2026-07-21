import 'package:flutter/material.dart';
import '../services/quorum_engine.dart';

/// Module C — Quorum Panel Widget
///
/// Displays live or historical quorum status with two circular progress gauges
/// and a clear valid/invalid badge. Used in:
/// - [GramSabhaLogScreen] — live, updates on every attendance change
/// - [MomViewerScreen] — historical, read-only
///
/// Per §7: always shows exact percentages — never just an icon.
class QuorumPanelWidget extends StatelessWidget {
  final QuorumResult quorum;
  final bool isLive; // if true, shows pulsing animation

  const QuorumPanelWidget({
    super.key,
    required this.quorum,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validColor = const Color(0xFF2E7D32);
    final invalidColor = const Color(0xFFC62828);
    final statusColor = quorum.qValid ? validColor : invalidColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'गणपूर्ती | Quorum',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusBadge(
                isValid: quorum.qValid,
                color: statusColor,
                isLive: isLive,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gauges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircularGauge(
                label: 'Attendance\n(A/R ≥ 50%)',
                value: quorum.attendanceRatio,
                pct: quorum.attendanceRatioPct,
                thresholdPct: 50,
                color: statusColor,
              ),
              _CircularGauge(
                label: 'Women\n(W/A ≥ 33%)',
                value: quorum.womenRatio,
                pct: quorum.womenRatioPct,
                thresholdPct: 33.3,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Count row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CountChip(label: 'Present', value: quorum.a, icon: Icons.person),
              _CountChip(
                  label: 'Face Match',
                  value: quorum.faceMatchedCount,
                  icon: Icons.face,
                  color: Colors.green.shade700),
              _CountChip(
                  label: 'Manual',
                  value: quorum.manualAddedCount,
                  icon: Icons.edit,
                  color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation text (always shown — §7 explainability)
          Text(
            quorum.explain(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: quorum.qValid
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal sub-widgets ──────────────────────────────────────────────────────

class _StatusBadge extends StatefulWidget {
  final bool isValid;
  final Color color;
  final bool isLive;

  const _StatusBadge({
    required this.isValid,
    required this.color,
    required this.isLive,
  });

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLive) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.isLive ? _pulse : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isValid ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: widget.color,
            ),
            const SizedBox(width: 4),
            Text(
              widget.isValid ? 'COMPLIANT' : 'FLAGGED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final double pct;   // actual percentage to display
  final double thresholdPct;
  final Color color;

  const _CircularGauge({
    required this.label,
    required this.value,
    required this.pct,
    required this.thresholdPct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final met = pct >= thresholdPct;
    final gaugeColor = met ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value.clamp(0.0, 1.0),
                strokeWidth: 8,
                backgroundColor: gaugeColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(gaugeColor),
              ),
              Center(
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: gaugeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;

  const _CountChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
