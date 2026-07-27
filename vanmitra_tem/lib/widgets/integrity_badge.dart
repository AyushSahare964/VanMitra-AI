import 'package:flutter/material.dart';

/// Displays the hash-chain integrity status of a [MomRecord].
///
/// Three possible states — never hidden or softened:
///   ✅ green  — both local chain and Firestore chain verified
///   ⚠️ amber  — local record assembled offline, not yet synced to Firestore
///   ❌ red    — tamper detected (hash mismatch on local or remote verify)
///
/// The ❌ state is ALWAYS displayed prominently — it is a critical compliance
/// indicator and must never be reduced to a tooltip or hidden in a submenu.
enum IntegrityStatus {
  verified,   // both local + Firestore verified
  pending,    // offline / not yet synced
  tampered,   // hash mismatch detected
}

class IntegrityBadge extends StatelessWidget {
  final IntegrityStatus status;

  /// Optional: loading state while async [verifyChain()] is running
  final bool isChecking;

  const IntegrityBadge({
    super.key,
    required this.status,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return _buildBadge(
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: 'Verifying chain…',
        color: Colors.blueGrey,
        bgColor: Colors.blueGrey.shade50,
      );
    }

    switch (status) {
      case IntegrityStatus.verified:
        return _buildBadge(
          icon: const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
          label: 'Hash-chain verified ✅',
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
        );
      case IntegrityStatus.pending:
        return _buildBadge(
          icon: const Icon(Icons.cloud_off, size: 14, color: Color(0xFFF57F17)),
          label: 'Pending sync — provisional ⚠️',
          color: const Color(0xFFF57F17),
          bgColor: const Color(0xFFFFF8E1),
        );
      case IntegrityStatus.tampered:
        return _buildBadge(
          icon: const Icon(Icons.gpp_bad, size: 14, color: Color(0xFFC62828)),
          label: 'Tamper detected — hash mismatch ❌',
          color: const Color(0xFFC62828),
          bgColor: const Color(0xFFFFEBEE),
          isBold: true,
        );
    }
  }

  Widget _buildBadge({
    required Widget icon,
    required String label,
    required Color color,
    required Color bgColor,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolves the correct [IntegrityStatus] from local and remote verify results.
IntegrityStatus resolveIntegrityStatus({
  required bool isSynced,
  required bool? localVerified,  // null while checking
  required bool? remoteVerified, // null while offline or checking
}) {
  if (localVerified == false || remoteVerified == false) {
    return IntegrityStatus.tampered;
  }
  if (!isSynced) return IntegrityStatus.pending;
  if (localVerified == true && remoteVerified == true) {
    return IntegrityStatus.verified;
  }
  return IntegrityStatus.pending;
}
