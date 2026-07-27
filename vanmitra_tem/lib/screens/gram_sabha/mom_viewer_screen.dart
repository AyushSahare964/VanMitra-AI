import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/mom_record.dart';
import '../../providers/gram_sabha_module_c_provider.dart';
import '../../services/local_ledger_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/geotag_stamp.dart';
import '../../widgets/integrity_badge.dart';
import '../../widgets/quorum_panel_widget.dart';
import '../../widgets/trilingual_summary_tabs.dart';
import '../../services/quorum_engine.dart';
import 'package:intl/intl.dart';

/// Module C §B.4 — MoM Viewer Screen
///
/// Displays all historical MoM records for the village with:
/// - List view: date, compliance chip, and [IntegrityBadge]
/// - Detail view: PDF preview, trilingual summary, quorum panel, geotag
///
/// The [IntegrityBadge] is always prominently shown — ❌ Tamper state
/// is never hidden or moved to a secondary location.
class MomViewerScreen extends ConsumerStatefulWidget {
  final String villageId;

  const MomViewerScreen({super.key, required this.villageId});

  @override
  ConsumerState<MomViewerScreen> createState() => _MomViewerScreenState();
}

class _MomViewerScreenState extends ConsumerState<MomViewerScreen> {
  MomRecord? _selectedRecord;
  bool _isVerifyingChain = false;
  bool? _localChainValid;
  bool? _remoteChainValid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(momRecordsProvider.notifier).loadFromHive(widget.villageId);
      _verifyChains();
    });
  }

  Future<void> _verifyChains() async {
    setState(() => _isVerifyingChain = true);
    final ledger = ref.read(localLedgerProvider(widget.villageId));
    final localResult = ledger.verifyChain();
    setState(() => _localChainValid = localResult.isValid);

    try {
      final fs = FirestoreService();
      final remoteResult = await fs.verifyMomChain(widget.villageId);
      if (mounted) setState(() => _remoteChainValid = remoteResult);
    } catch (_) {
      if (mounted) setState(() => _remoteChainValid = null); // offline
    } finally {
      if (mounted) setState(() => _isVerifyingChain = false);
    }
  }

  Future<void> _generateAndPreviewPdf(MomRecord record) async {
    final pdfService = ref.read(momPdfServiceProvider);
    final doc = await pdfService.render(record);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('MoM Preview'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  final bytes = await doc.save();
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'mom_${record.meetingId}.pdf',
                  );
                },
              ),
            ],
          ),
          body: PdfPreview(
            build: (_) => doc.save(),
            canChangePageFormat: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(momRecordsProvider);
    final theme = Theme.of(context);

    if (_selectedRecord != null) {
      return _buildDetailView(context, _selectedRecord!, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Records (MoM)'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isVerifyingChain
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_user),
            tooltip: 'Verify chain integrity',
            onPressed: _verifyChains,
          ),
        ],
      ),
      body: Column(
        children: [
          // Village-level chain integrity banner
          _ChainStatusBanner(
            isChecking: _isVerifyingChain,
            localValid: _localChainValid,
            remoteValid: _remoteChainValid,
            recordCount: records.length,
          ),

          // MoM record list
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No MoM records yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Records appear here after meetings are conducted\nand published to the ledger',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final record = records[i];
                      final integrityStatus = resolveIntegrityStatus(
                        isSynced: record.isSynced,
                        localVerified: _localChainValid,
                        remoteVerified: _remoteChainValid,
                      );
                      return _MomRecordCard(
                        record: record,
                        integrityStatus: integrityStatus,
                        onTap: () =>
                            setState(() => _selectedRecord = record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(
      BuildContext context, MomRecord record, ThemeData theme) {
    final quorum = QuorumResult(
      qValid: record.quorumValid,
      a: record.attendeeCount,
      r: record.registeredCount,
      w: record.womenCount,
      attendanceRatioPct: record.registeredCount > 0
          ? (record.attendeeCount / record.registeredCount * 100)
          : 0,
      womenRatioPct: record.attendeeCount > 0
          ? (record.womenCount / record.attendeeCount * 100)
          : 0,
      faceMatchedCount: record.faceMatchedCount,
      manualAddedCount: record.manualAddedCount,
    );

    final integrityStatus = resolveIntegrityStatus(
      isSynced: record.isSynced,
      localVerified: _localChainValid,
      remoteVerified: _remoteChainValid,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MoM — ${DateFormat('dd MMM yyyy').format(DateTime.parse(record.meetingDate))}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedRecord = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Preview PDF',
            onPressed: () => _generateAndPreviewPdf(record),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Integrity badge — always at top, never hidden
            IntegrityBadge(
              status: integrityStatus,
              isChecking: _isVerifyingChain,
            ),
            const SizedBox(height: 12),

            // Geotag stamp
            GeotagStamp(
              geotag: record.geotag,
              timestamp: DateTime.parse(record.meetingDate),
            ),
            const SizedBox(height: 16),

            // Quorum panel (read-only historical)
            QuorumPanelWidget(quorum: quorum, isLive: false),
            const SizedBox(height: 16),

            // Trilingual resolution summary (read-only)
            Text(
              'ठराव | Resolution',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TrilingualSummaryTabs(
              textEn: record.decisionTextEn,
              textHi: record.decisionTextHi,
              textMr: record.decisionTextMr,
              isEditable: false,
            ),
            const SizedBox(height: 16),

            // Hash stamp
            _HashStamp(record: record),
          ],
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _MomRecordCard extends StatelessWidget {
  final MomRecord record;
  final IntegrityStatus integrityStatus;
  final VoidCallback onTap;

  const _MomRecordCard({
    required this.record,
    required this.integrityStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(record.meetingDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date block
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date != null ? DateFormat('dd').format(date) : '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    Text(
                      date != null ? DateFormat('MMM').format(date) : '',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: record.quorumValid
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.quorumValid
                                ? '✅ Compliant'
                                : '⚠️ Flagged',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: record.quorumValid
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IntegrityBadge(status: integrityStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A: ${record.attendeeCount}  W: ${record.womenCount}  R: ${record.registeredCount}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChainStatusBanner extends StatelessWidget {
  final bool isChecking;
  final bool? localValid;
  final bool? remoteValid;
  final int recordCount;

  const _ChainStatusBanner({
    required this.isChecking,
    required this.localValid,
    required this.remoteValid,
    required this.recordCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return Container(
        color: Colors.blueGrey.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text('Verifying $recordCount blocks…',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
      );
    }

    final tampered = localValid == false || remoteValid == false;
    final color = tampered
        ? const Color(0xFFC62828)
        : (localValid == true && remoteValid == true)
            ? const Color(0xFF2E7D32)
            : const Color(0xFFF57F17);
    final label = tampered
        ? '❌ TAMPER DETECTED — $recordCount blocks — one or more records modified'
        : (localValid == true && remoteValid == true)
            ? '✅ Chain integrity verified — $recordCount blocks'
            : '⚠️ $recordCount blocks — partial verification (offline?)';

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HashStamp extends StatelessWidget {
  final MomRecord record;
  const _HashStamp({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Integrity Stamp',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey),
          ),
          const SizedBox(height: 4),
          _HashLine('Local Hash',
              record.localHash.length > 32
                  ? '${record.localHash.substring(0, 32)}…'
                  : record.localHash),
          if (record.canonicalHash != null)
            _HashLine('Canonical',
                record.canonicalHash!.length > 32
                    ? '${record.canonicalHash!.substring(0, 32)}…'
                    : record.canonicalHash!),
          _HashLine(
              'Synced', record.isSynced ? '✓ Yes' : '⏳ Pending'),
        ],
      ),
    );
  }
}

class _HashLine extends StatelessWidget {
  final String label;
  final String value;
  const _HashLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
