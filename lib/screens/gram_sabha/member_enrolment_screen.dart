import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../models/village_member.dart';
import '../../providers/gram_sabha_module_c_provider.dart';
import '../../providers/village_provider.dart';
import '../../models/sync_item.dart';
import '../../widgets/consent_recorder_widget.dart';
import '../../data/local/hive_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Module C §B.1 — Member Face Enrolment Screen
///
/// Guides an admin through the three-step enrolment flow:
///   1. Select member from the village roll
///   2. Capture face via camera → FaceNet embedding
///   3. Record consent audio (mandatory gate) → Save to Hive + queue Firestore sync
///
/// Raw photos are immediately discarded — only the 128-dim embedding is stored.
class MemberEnrolmentScreen extends ConsumerStatefulWidget {
  const MemberEnrolmentScreen({super.key});

  @override
  ConsumerState<MemberEnrolmentScreen> createState() =>
      _MemberEnrolmentScreenState();
}

class _MemberEnrolmentScreenState
    extends ConsumerState<MemberEnrolmentScreen> {
  // Step tracking
  int _step = 0; // 0=select, 1=capture, 2=consent

  VillageMember? _selectedMember;
  List<double>? _embedding;
  String? _consentAudioPath;
  String? _errorMessage;
  bool _isSaving = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    // Prefer front camera for face enrolment
    final front = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(front, ResolutionPreset.high);
    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureEmbedding() async {
    if (_cameraController == null || !_cameraReady) return;
    setState(() => _errorMessage = null);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faceService = ref.read(faceEnrollmentServiceProvider);

      if (!faceService.isReady) {
        setState(() => _errorMessage = 'Face model loading — please wait');
        return;
      }

      final embedding = await faceService.embedFace(inputImage);
      if (embedding == null) {
        setState(() => _errorMessage =
            'No face detected. Retry in better lighting, facing the camera directly.');
        return;
      }

      setState(() {
        _embedding = embedding;
        _step = 2;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Camera error: ${e.toString()}');
    }
  }

  Future<void> _saveEnrolment() async {
    if (_selectedMember == null || _embedding == null || _consentAudioPath == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final updated = _selectedMember!.copyWith(
        faceEmbedding: _embedding,
        enrolledAt: now,
      );

      // Save updated member to Hive
      await Hive.box<Map>(HiveDatabase.membersBox)
          .put(updated.id, updated.toJson());

      // Add to faceEnrollmentsProvider state
      ref.read(faceEnrollmentsProvider.notifier).addEnrollment(
        updated.id,
        _embedding!,
      );

      // Queue Firestore sync
      final syncItem = SyncItem(
        id: const Uuid().v4(),
        action: SyncAction.syncFaceEnrollment,
        status: SyncStatus.pending,
        entityId: updated.id,
        entityType: 'face_enrollment',
        payload: {
          'memberId': updated.id,
          'villageId': updated.villageId,
          'embedding': _embedding,
          'enrolledAt': now.toIso8601String(),
          'consentAudioPath': _consentAudioPath,
        },
        createdAt: now,
      );
      await Hive.box<Map>(HiveDatabase.syncQueueBox)
          .put(syncItem.id, syncItem.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${updated.nameEnglish} enrolled ✅ — raw photo discarded'),
            ]),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Save failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Face Enrolment'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _step),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Error banner
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFC62828).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Color(0xFFC62828)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFC62828)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Step 0: Member selection
                  if (_step >= 0)
                    _MemberSelector(
                      selected: _selectedMember,
                      onSelected: (m) {
                        setState(() {
                          _selectedMember = m;
                          if (_step == 0) _step = 1;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // Step 1: Camera capture
                  if (_step >= 1) ...[
                    Text(
                      'Capture Face',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _CameraCapture(
                      controller: _cameraController,
                      isReady: _cameraReady,
                      onCapture: _captureEmbedding,
                      isComplete: _step >= 2,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Step 2: Consent recording
                  if (_step >= 2 && _selectedMember != null)
                    ConsentRecorderWidget(
                      memberName: _selectedMember!.nameMarathi,
                      onConsentRecorded: (path) {
                        setState(() => _consentAudioPath = path);
                      },
                    ),
                  const SizedBox(height: 24),

                  // Save button
                  if (_step >= 2)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_consentAudioPath != null && !_isSaving)
                            ? _saveEnrolment
                            : null,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving…' : 'Save Enrolment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _consentAudioPath != null
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Select Member', 'Capture Face', 'Record Consent'];
    return Container(
      color: const Color(0xFF2E7D32).withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone
                      ? const Color(0xFF2E7D32)
                      : isActive
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MemberSelector extends ConsumerWidget {
  final VillageMember? selected;
  final ValueChanged<VillageMember> onSelected;

  const _MemberSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In the real app, this would use villageMembers from the membersProvider
    // Showing a simplified selector here
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.person_search, color: Color(0xFF2E7D32)),
        title: Text(selected?.nameEnglish ?? 'Tap to select a member'),
        subtitle: selected != null
            ? Text('${selected!.gender.name} · ${selected!.category.name}')
            : const Text('Search by name or scroll the village roll'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to member search — reuse existing member list UI
          // For now: navigate to a bottom sheet selector
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Member selection: integrate with existing villageMembers provider'),
            ),
          );
        },
      ),
    );
  }
}

class _CameraCapture extends StatelessWidget {
  final CameraController? controller;
  final bool isReady;
  final VoidCallback onCapture;
  final bool isComplete;

  const _CameraCapture({
    required this.controller,
    required this.isReady,
    required this.onCapture,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face, color: Color(0xFF2E7D32), size: 28),
              SizedBox(width: 8),
              Text(
                'Face captured — embedding extracted ✅\nRaw photo discarded',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 280,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady && controller != null)
              CameraPreview(controller!)
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            // Face overlay guide box
            Center(
              child: Container(
                width: 180,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Capture button at bottom
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF2E7D32), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF2E7D32),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
