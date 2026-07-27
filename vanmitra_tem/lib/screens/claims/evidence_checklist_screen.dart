import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../models/claim.dart';
import '../../providers/claims_provider.dart';
import '../../providers/module_a_provider.dart';
import '../../config/ai_agent_config.dart';
import '../../services/module_a_service.dart';
import '../../services/evidence_score_service.dart';
import '../../widgets/portal_frame_scaffold.dart';
import '../../widgets/evidence_strength_gauge.dart';
import '../../services/localization_service.dart';

/// Evidence Checklist Screen — the core Model A interaction point.
///
/// Shows a table of 6 evidence categories (from AiAgentConfig weights).
/// Per row: upload button → OCR spinner → inline verdict chip.
/// EvidenceStrengthGauge pinned at top updates live.
///
/// When online: calls AIModuleAService.verifyDocument() via FastAPI.
/// When offline: marks as 'needs_review', enqueues for later sync.
class EvidenceChecklistScreen extends ConsumerStatefulWidget {
  const EvidenceChecklistScreen({super.key});

  @override
  ConsumerState<EvidenceChecklistScreen> createState() =>
      _EvidenceChecklistScreenState();
}

class _EvidenceChecklistScreenState
    extends ConsumerState<EvidenceChecklistScreen> {
  String? _claimId;
  Claim? _claim;

  // Verification state per category
  final Map<String, String> _verificationStatus = {};
  final Set<String> _uploadingCategories = {};
  final Map<String, String> _extractedPreviews = {};

  final _scorer = EvidenceScoreService();
  final _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _claimId == null) {
      _claimId = args;
      _loadClaim();
    }
  }

  void _loadClaim() {
    final claims = ref.read(claimsProvider);
    _claim = claims.claims
        .cast<Claim?>()
        .firstWhere((c) => c?.id == _claimId, orElse: () => null);
    if (_claim != null) {
      setState(() {
        for (final entry in _claim!.evidenceFlags.entries) {
          if (entry.value) {
            _verificationStatus[entry.key] = 'auto_verified';
          }
        }
      });
    }
  }

  double _currentScore(Map<String, double> weights) {
    final flags = {
      for (final k in weights.keys)
        k: _verificationStatus[k] == 'auto_verified',
    };
    return _scorer.calculateWithWeights(flags, weights).score;
  }

  Future<void> _uploadForCategory(
    String category,
    AiAgentConfig config,
    ModuleAService service,
  ) async {
    final imageFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (imageFile == null) return;

    setState(() => _uploadingCategories.add(category));

    try {
      final bytes = await imageFile.readAsBytes();

      // Call DocVerifyAgent via FastAPI (or DefaultModuleAService offline)
      final result = await service.verifyDocument(bytes, category);

      setState(() {
        _verificationStatus[category] = result.verificationStatus;
        if (result.extractedTextPreview.isNotEmpty) {
          _extractedPreviews[category] = result.extractedTextPreview;
        }
      });

      // Update claim in Hive
      if (_claim != null) {
        final updatedFlags = Map<String, bool>.from(_claim!.evidenceFlags)
          ..[category] = result.verificationStatus == 'auto_verified';
        final updatedScore =
            _scorer.calculateWithWeights(updatedFlags, config.evidenceWeights).score;
        final updated = _claim!.copyWith(
          evidenceFlags: updatedFlags,
          evidenceScore: updatedScore,
        );
        await ref.read(claimsProvider.notifier).updateClaim(updated);
        setState(() => _claim = updated);
      }

      // Show verdict snackbar
      if (mounted) {
        _showVerdictSnack(result);
      }
    } on ModuleAServiceException catch (e) {
      print('AI Service Error ($category): $e');
      setState(() => _verificationStatus[category] = 'needs_review');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('upload_offline_error')} ${e.message}',
              style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
            backgroundColor: AppColors.warningAmber,
          ),
        );
      }
    } catch (e, st) {
      print('Generic Error ($category): $e\\n$st');
      setState(() => _verificationStatus[category] = 'needs_review');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection Error: Could not reach backend.',
              style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _uploadingCategories.remove(category));
    }
  }

  void _showVerdictSnack(DocumentVerifyResult result) {
    Color bg;
    String msg;
    switch (result.verificationStatus) {
      case 'auto_verified':
        bg = AppColors.successGreen;
        msg = '${context.tr('upload_verified')} (${(result.matchConfidence * 100).toStringAsFixed(0)}% ${context.tr('match')})';
        break;
      case 'needs_review':
        bg = AppColors.warningAmber;
        msg = '${context.tr('upload_review')} (${(result.matchConfidence * 100).toStringAsFixed(0)}% ${context.tr('match')})';
        break;
      default:
        bg = AppColors.alertRed;
        msg = context.tr('upload_rejected');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'NotoSansDevanagari')),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(aiAgentConfigProvider);
    final service = ref.watch(moduleAProvider);

    return PortalFrameScaffold(
      breadcrumbs: [context.tr('tab_dashboard'), context.tr('claims'), context.tr('action_new_claim'), context.tr('breadcrumbs_evidence')],
      body: configAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Config error: $e')),
        data: (config) => _buildBody(config, service),
      ),
    );
  }

  Widget _buildBody(AiAgentConfig config, ModuleAService service) {
    final weights = config.evidenceWeights;
    final score = _currentScore(weights);
    final presentCount = _verificationStatus.values
        .where((s) => s == 'auto_verified')
        .length;

    return Column(
      children: [
        // ── Live Evidence Gauge ──────────────────────────────────────────
        EvidenceStrengthGauge(
          score: score,
          presentCount: presentCount,
          totalCount: weights.length,
        ),

        // ── Table header ─────────────────────────────────────────────────
        Container(
          color: AppColors.govtBlue,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  context.tr('evidence_category'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  context.tr('evidence_weight'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.tr('evidence_status'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 72),
            ],
          ),
        ),

        // ── Evidence table rows ──────────────────────────────────────────
        Expanded(
          child: ListView(
            children: [
              for (final entry in weights.entries)
                EvidenceTableRow(
                  categoryKey: entry.key,
                  categoryLabelMr:
                      context.tr('ev_cat_${entry.key}'),
                  weight: entry.value,
                  verificationStatus:
                      _verificationStatus[entry.key] == null ? context.tr('evidence_unverified') : _verificationStatus[entry.key]!,
                  isUploading:
                      _uploadingCategories.contains(entry.key),
                  onUpload: () =>
                      _uploadForCategory(entry.key, config, service),
                ),

              const SizedBox(height: 16),

              // Rule 13 reference
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.govtBlue.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.govtBlue.withOpacity(0.2)),
                  ),
                  child: Text(
                    context.tr('evidence_rule_13_note'),
                    style: const TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 11,
                      color: AppColors.govtBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // ── Continue button ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: score >= 0.4
                  ? () => Navigator.pushNamed(
                        context,
                        '/claims/draft',
                        arguments: _claimId,
                      )
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                score >= 0.8
                    ? context.tr('btn_next_draft')
                    : score >= 0.6
                        ? context.tr('btn_next_incomplete')
                        : context.tr('btn_more_evidence_needed'),
                style: const TextStyle(fontFamily: 'NotoSansDevanagari'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: score >= 0.8
                    ? AppColors.successGreen
                    : score >= 0.6
                        ? AppColors.warningAmber
                        : AppColors.govtBlue.withOpacity(0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
