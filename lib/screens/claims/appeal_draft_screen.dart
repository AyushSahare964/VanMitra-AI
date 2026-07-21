import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/claim.dart';
import '../../providers/claims_provider.dart';
import '../../providers/module_a_provider.dart';
import '../../services/module_a_service.dart';
import '../../widgets/portal_frame_scaffold.dart';
import '../../widgets/document_paper_card.dart';

/// Appeal Draft Screen — calls AppealAgent via FastAPI /api/v1/generate-appeal.
///
/// Shows DocumentPaperCard with Section 6 appeal text.
/// Same approve/edit/submit flow as DraftPreviewScreen.
/// Displays 60-day appeal deadline countdown prominently.
class AppealDraftScreen extends ConsumerStatefulWidget {
  const AppealDraftScreen({super.key});

  @override
  ConsumerState<AppealDraftScreen> createState() =>
      _AppealDraftScreenState();
}

class _AppealDraftScreenState
    extends ConsumerState<AppealDraftScreen> {
  String? _claimId;
  RejectionAnalysis? _rejectionAnalysis;
  Claim? _claim;
  AppealDraftResult? _appeal;
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSubmitting = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && _claimId == null) {
      _claimId = args['claimId'] as String?;
      _rejectionAnalysis = args['analysis'] as RejectionAnalysis?;
      _loadAppeal();
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadAppeal() async {
    final claims = ref.read(claimsProvider);
    _claim = claims.claims
        .cast<Claim?>()
        .firstWhere((c) => c?.id == _claimId, orElse: () => null);

    if (_claim == null || _rejectionAnalysis == null) {
      setState(() => _isLoading = false);
      return;
    }

    final service = ref.read(moduleAProvider);

    try {
      final appeal = await service.generateAppeal(
        rejection: _rejectionAnalysis!,
        originalClaim: _claim!,
      );
      setState(() {
        _appeal = appeal;
        _editController.text = appeal.appealText;
        _isLoading = false;
      });
    } on ModuleAServiceException catch (_) {
      final fallback = DefaultModuleAService();
      final appeal = await fallback.generateAppeal(
        rejection: _rejectionAnalysis!,
        originalClaim: _claim!,
      );
      setState(() {
        _appeal = appeal;
        _editController.text = appeal.appealText;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAppeal() async {
    if (_claim == null) return;
    setState(() => _isSubmitting = true);

    final updated = _claim!.copyWith(status: ClaimStatus.appealFiled);
    await ref.read(claimsProvider.notifier).updateClaim(updated);
    setState(() {
      _claim = updated;
      _isSubmitting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ अपील सादर झाले! SDLC कार्यालयाला द्या.',
            style: TextStyle(fontFamily: 'NotoSansDevanagari'),
          ),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalFrameScaffold(
      breadcrumbs: const [
        'मुख्यपृष्ठ',
        'माझे दावे',
        'नामंजुरी विश्लेषण',
        'अपील मसुदा'
      ],
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.govtBlue),
                  SizedBox(height: 16),
                  Text(
                    'AI अपील मसुदा तयार करत आहे…',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 14,
                      color: AppColors.govtBlue,
                    ),
                  ),
                ],
              ),
            )
          : _appeal == null
              ? const Center(child: Text('अपील तयार करता आले नाही.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Appeal deadline chip
                      if (_appeal!.appealDeadline != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(
                              16, 12, 16, 0),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.warningAmber
                                    .withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: AppColors.warningAmber,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'अपील मुदत: ${_formatDate(_appeal!.appealDeadline!)}  (60 दिवस — FRA Sec. 6)',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansDevanagari',
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      DocumentPaperCard(
                        draftText: _appeal!.appealText,
                        isAIGenerated: _appeal!.isAIGenerated,
                        title: 'कलम 6 अपील — वन हक्क कायदा 2006',
                        isEditMode: _isEditMode,
                        editController: _editController,
                        onEdit: () =>
                            setState(() => _isEditMode = !_isEditMode),
                        onApprove:
                            _isSubmitting ? null : _submitAppeal,
                      ),

                      if (_isSubmitting)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.govtBlue),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
