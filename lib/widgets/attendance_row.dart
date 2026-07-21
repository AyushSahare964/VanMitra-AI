import 'package:flutter/material.dart';
import '../services/quorum_engine.dart';
import 'package:intl/intl.dart';

/// Displays a single attendee row in the attendance list during a live Gram Sabha
/// or in the historical MoM view.
///
/// Verification method is always visibly tagged — face_match (green) vs manual (amber) —
/// as per §4.2: manual additions must never be silently mixed with biometric ones.
class AttendanceRow extends StatelessWidget {
  final AttendanceEntry entry;
  final VoidCallback? onRemove; // null in historical/read-only mode

  const AttendanceRow({
    super.key,
    required this.entry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFaceMatch = entry.captureMethod == 'face_match';
    final chipColor =
        isFaceMatch ? const Color(0xFF2E7D32) : const Color(0xFFF57F17);
    final chipBg = isFaceMatch
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF8E1);
    final chipLabel = isFaceMatch ? '✓ Face Match' : '✎ Manual';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: chipColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle with gender-colored background
          CircleAvatar(
            radius: 18,
            backgroundColor:
                entry.isWoman ? const Color(0xFFE8EAF6) : const Color(0xFFE3F2FD),
            child: Icon(
              entry.isWoman ? Icons.woman : Icons.man,
              size: 18,
              color: entry.isWoman
                  ? const Color(0xFF3949AB)
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),

          // Name + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.memberName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(entry.checkedInAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Verification method chip — always visible, never hidden
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chipColor.withOpacity(0.4)),
            ),
            child: Text(
              chipLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Remove button (hidden in read-only mode)
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              color: Colors.red.shade300,
              tooltip: 'Remove attendee',
              onPressed: onRemove,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
