import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays a compact GPS + timestamp stamp.
///
/// Used on evidence photo cards, MoM header, MoM PDF, meeting metadata strip.
/// The geotag is the canonical "lat,lng" string stored in [MomRecord.geotag].
class GeotagStamp extends StatelessWidget {
  /// Coordinates as "lat,lng" e.g. "19.7800,73.2200"
  final String geotag;
  final DateTime timestamp;
  final bool compact; // if true, shows one-line; false shows two-line

  const GeotagStamp({
    super.key,
    required this.geotag,
    required this.timestamp,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = geotag.split(',');
    final lat = parts.isNotEmpty ? double.tryParse(parts[0].trim()) : null;
    final lng = parts.length > 1 ? double.tryParse(parts[1].trim()) : null;

    final latStr = lat != null
        ? '${lat.abs().toStringAsFixed(4)}°${lat >= 0 ? 'N' : 'S'}'
        : geotag;
    final lngStr = lng != null
        ? '${lng.abs().toStringAsFixed(4)}°${lng >= 0 ? 'E' : 'W'}'
        : '';

    final dateStr = DateFormat('dd MMM yyyy').format(timestamp.toLocal());
    final timeStr = DateFormat('hh:mm a').format(timestamp.toLocal());

    if (compact) {
      return _chip(
        '📍 $latStr, $lngStr  🕒 $timeStr  📅 $dateStr',
        context,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('📍 $latStr, $lngStr', context),
        const SizedBox(height: 4),
        _chip('🕒 $timeStr  ·  📅 $dateStr', context),
      ],
    );
  }

  Widget _chip(String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
