import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/van_mitra_app_shell.dart';

/// Module B — CFR Boundary Map Screen
///
/// Shows the Community Forest Resource boundary on a map with
/// change-alert overlay and a slide-up alert detail panel.
/// Design reference: stitch_mahagov_citizen_portal_app/cfr_boundary_map/
class BoundaryMapScreen extends StatefulWidget {
  const BoundaryMapScreen({super.key});

  @override
  State<BoundaryMapScreen> createState() => _BoundaryMapScreenState();
}

class _BoundaryMapScreenState extends State<BoundaryMapScreen>
    with TickerProviderStateMixin {
  double _zoomLevel = 1.0;
  bool _alertDismissed = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: const VanMitraTopBar(),
      body: Stack(
        children: [
          // ── Map Canvas ───────────────────────────────────────────────────
          Positioned.fill(
            child: _MapCanvas(
              zoomLevel: _zoomLevel,
              pulseController: _pulseCtrl,
            ),
          ),

          // ── Floating Map Controls (top right) ────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _MapControlCard(
                  children: [
                    _MapControlButton(
                      icon: Icons.add,
                      onTap: () =>
                          setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.5, 2.0)),
                    ),
                    const Divider(height: 1, color: Color(0x22000000)),
                    _MapControlButton(
                      icon: Icons.remove,
                      onTap: () =>
                          setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.5, 2.0)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MapControlCard(
                  children: [
                    _MapControlButton(
                      icon: Icons.my_location,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Centering on your location…'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MapControlCard(
                  children: [
                    _MapControlButton(
                      icon: Icons.layers_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Alert Panel (bottom) ──────────────────────────────────────────
          if (!_alertDismissed)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _AlertPanel(
                onDismiss: () => setState(() => _alertDismissed = true),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          const VanMitraBottomNav(activeTab: VanMitraTab.map),
    );
  }
}

// ── Map Canvas ───────────────────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  final double zoomLevel;
  final AnimationController pulseController;

  const _MapCanvas({
    required this.zoomLevel,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _MapPainter(zoom: zoomLevel),
        child: Stack(
          children: [
            // Village label
            Positioned(
              left: MediaQuery.of(context).size.width * 0.38,
              top: MediaQuery.of(context).size.height * 0.28,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kOutlineVariant),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ozhar',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kOnSurface)),
                    Text('CFR',
                        style:
                            TextStyle(fontSize: 11, color: kOnSurfaceVariant)),
                  ],
                ),
              ),
            ),

            // Alert marker (pulsing)
            Positioned(
              left: MediaQuery.of(context).size.width * 0.62,
              top: MediaQuery.of(context).size.height * 0.42,
              child: _PulsingMarker(controller: pulseController),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final double zoom;
  _MapPainter({required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    // Background — map-like beige/green tones
    final bgPaint = Paint()..color = const Color(0xFFE8E0D0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Simulate map tiles with subtle grid
    final gridPaint = Paint()
      ..color = const Color(0xFFCFCBBF)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Forest/green areas
    final forestPaint = Paint()..color = const Color(0xFFBED5A8).withValues(alpha: 0.8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.35, size.height * 0.4),
          width: size.width * 0.5,
          height: size.height * 0.4),
      forestPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.75, size.height * 0.25),
          width: size.width * 0.3,
          height: size.height * 0.2),
      forestPaint,
    );

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFE8C97A)
      ..strokeWidth = 4 * zoom
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.45, size.height * 0.7),
      roadPaint,
    );

    // CFR Boundary polygon (dashed green)
    final w = size.width;
    final h = size.height;
    final boundaryPoints = [
      Offset(w * 0.18, h * 0.18),
      Offset(w * 0.72, h * 0.12),
      Offset(w * 0.88, h * 0.48),
      Offset(w * 0.62, h * 0.75),
      Offset(w * 0.20, h * 0.70),
      Offset(w * 0.10, h * 0.40),
    ];

    // Fill
    final fillPaint = Paint()
      ..color = kStatusSuccess.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final fillPath = Path()..addPolygon(boundaryPoints, true);
    canvas.drawPath(fillPath, fillPaint);

    // Dashed border
    _drawDashedPolygon(canvas, boundaryPoints, kStatusSuccess, 3.0 * zoom);

    // Map labels (simulated text blocks as rectangles)
    final labelPaint = Paint()..color = const Color(0xFF8A8070).withValues(alpha: 0.5);
    for (final offset in [
      Offset(w * 0.05, h * 0.55),
      Offset(w * 0.15, h * 0.75),
      Offset(w * 0.55, h * 0.85),
      Offset(w * 0.75, h * 0.65),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, 60, 8),
          const Radius.circular(2),
        ),
        labelPaint,
      );
    }
  }

  void _drawDashedPolygon(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashLength = 10.0;
    const gapLength = 6.0;

    for (int i = 0; i < points.length; i++) {
      final start = points[i];
      final end = points[(i + 1) % points.length];
      _drawDashedLine(canvas, start, end, paint, dashLength, gapLength);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashLength, double gapLength) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final unitX = dx / len;
    final unitY = dy / len;
    double pos = 0;
    bool drawing = true;
    while (pos < len) {
      final segLen = drawing ? dashLength : gapLength;
      final next = math.min(pos + segLen, len);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * pos, start.dy + unitY * pos),
          Offset(start.dx + unitX * next, start.dy + unitY * next),
          paint,
        );
      }
      pos = next;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.zoom != zoom;
}

class _PulsingMarker extends StatelessWidget {
  final AnimationController controller;
  const _PulsingMarker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final v = controller.value;
              return Opacity(
                opacity: (1.0 - v) * 0.6,
                child: Transform.scale(
                  scale: 0.8 + v * 1.4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kStatusError.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
          // Core
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kStatusError,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.warning_rounded,
                color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

// ── Map Controls ─────────────────────────────────────────────────────────────

class _MapControlCard extends StatelessWidget {
  final List<Widget> children;
  const _MapControlCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kOutlineVariant.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: kOnSurface, size: 22),
      ),
    );
  }
}

// ── Alert Panel ───────────────────────────────────────────────────────────────

class _AlertPanel extends StatelessWidget {
  final VoidCallback onDismiss;
  const _AlertPanel({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            top: BorderSide(color: kStatusError, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: kStatusError, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Change Alert Detected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kOnSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kStatusError,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HIGH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x1A000000)),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _AlertMetric(
                            label: 'AREA AFFECTED', value: '0.5 ha')),
                    Expanded(
                        child: _AlertMetric(
                            label: 'DETECTED', value: 'July 10, 2024')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('LIKELY CAUSE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kOnSurfaceVariant,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.forest_outlined,
                        color: kStatusWarning, size: 20),
                    SizedBox(width: 8),
                    Text('Illegal Clearing / Logging',
                        style:
                            TextStyle(fontSize: 16, color: kOnSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('SENSOR DATA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kOnSurfaceVariant,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: kOutlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ΔNDVI Drop',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kOnSurface)),
                      Text('< -0.2',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kStatusError)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Report sent to Forest Rights Committee'),
                          backgroundColor: kStatusSuccess,
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_outlined, size: 20),
                    label: const Text(
                      'Report to FRC',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kOnPrimary,
                      shape: const StadiumBorder(),
                      elevation: 1,
                    ),
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

class _AlertMetric extends StatelessWidget {
  final String label;
  final String value;
  const _AlertMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kOnSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
          ),
        ),
      ],
    );
  }
}
