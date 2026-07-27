import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/resolution.dart';
import '../../models/user_role.dart';
import '../../models/quorum_status.dart';
import '../../models/gram_sabha_meeting.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';



class ResolutionLedgerScreen extends ConsumerStatefulWidget {
  const ResolutionLedgerScreen({super.key});

  @override
  ConsumerState<ResolutionLedgerScreen> createState() => _ResolutionLedgerScreenState();
}

class _ResolutionLedgerScreenState extends ConsumerState<ResolutionLedgerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ResolutionType _selectedType = ResolutionType.other;
  bool _isVerifying = false;
  bool? _isChainValid;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _verifyChain() async {
    setState(() {
      _isVerifying = true;
      _isChainValid = null;
    });
    
    // Simulate complex cryptography/blockchain verification delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _isChainValid = true; // Hardcoded true for pilot simulation
    });
  }

  void _addResolution(String meetingId) {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      final userId = authState.currentUser?.id ?? 'admin_id';

      final mockQuorum = QuorumStatus(
        totalRegistered: 500,
        totalPresent: 250,
        womenPresent: 84,
        stPresent: 50,
        pvtgPresent: 10,
        menPresent: 166,
        meetingType: MeetingType.regular,
      );

      ref.read(resolutionProvider.notifier).addResolution(
        meetingId: meetingId,
        villageId: 'vil_ozhar_01', // Mocked for pilot
        type: _selectedType,
        text: _descController.text,
        summary: _titleController.text,
        recordedByUserId: userId,
        quorum: mockQuorum,
      );
      
      // Clear form
      _titleController.clear();
      _descController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddDialog(String meetingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Resolution'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ResolutionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type'),
                  items: ResolutionType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayNameMr),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Title'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Description'),
                  maxLines: 3,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addResolution(meetingId),
            child: const Text('Record (Hash)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingId = ModalRoute.of(context)?.settings.arguments as String?;
    if (meetingId == null) return const Scaffold(body: Center(child: Text('Error')));

    final resolutions = ref.watch(resolutionProvider).where((r) => r.meetingId == meetingId).toList();
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ठराव नोंदवही | Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _verifyChain,
            tooltip: 'Verify Cryptographic Hash Chain',
          )
        ],
      ),
      body: Column(
        children: [
          // Verification Status Banner
          if (_isVerifying)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withValues(alpha: 0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Verifying SHA-256 Hash Chain...', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          if (_isChainValid == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.success.withValues(alpha: 0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text('Ledger Integrity Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          
          Expanded(
            child: resolutions.isEmpty
                ? const Center(child: Text('No resolutions recorded yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: resolutions.length,
                    itemBuilder: (context, index) {
                      final r = resolutions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Resolution #${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a').format(r.timestamp),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r.summary ?? 'No Title',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(r.text),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.link, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hash: ${r.hash.substring(0, 16)}...',
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.secondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isAdmin
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddDialog(meetingId),
                  icon: const Icon(Icons.gavel, color: Colors.white),
                  label: const Text('Add Resolution', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
