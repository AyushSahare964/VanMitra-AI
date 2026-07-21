import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gram_sabha_meeting.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../core/routes/app_router.dart';

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get meeting ID from route arguments
    final meetingId = ModalRoute.of(context)?.settings.arguments as String?;
    if (meetingId == null) {
      return const Scaffold(body: Center(child: Text('Meeting ID not provided')));
    }

    final meetingsState = ref.watch(meetingsProvider);
    final meeting = _findMeeting(meetingsState, meetingId);

    if (meeting == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Not Found')),
        body: const Center(child: Text('The requested meeting could not be found.')),
      );
    }

    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('सभेचा तपशील | Details'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(meeting.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              meeting.status.name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meeting.type.displayNameMr,
              style: const TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('dd MMMM yyyy').format(meeting.scheduledDate)),
            _buildInfoRow(Icons.access_time, 'Time', DateFormat('hh:mm a').format(meeting.scheduledDate)),
            _buildInfoRow(Icons.location_on, 'Venue', meeting.venue),
            const SizedBox(height: 24),
            const Text(
              'अजेंडा | Agenda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (meeting.agenda != null && meeting.agenda!.isNotEmpty)
              ...meeting.agenda!.split('\n').where((s) => s.trim().isNotEmpty).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  )),
            const SizedBox(height: 32),
            if (isAdmin) _buildAdminControls(context, ref, meeting),
            if (!isAdmin) _buildVillagerControls(context, ref, meeting),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAdminControls(BuildContext context, WidgetRef ref, GramSabhaMeeting meeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text('Admin Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (meeting.status == MeetingStatus.scheduled)
          ElevatedButton(
            onPressed: () {
              ref.read(meetingsProvider.notifier).startMeeting(meeting.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Start Meeting'),
          ),
        if (meeting.status == MeetingStatus.inProgress) ...[
          OutlinedButton.icon(
            onPressed: () {
              // Navigate to attendance management
              Navigator.pushNamed(
                context,
                AppRouter.attendanceManagement,
                arguments: {
                  'meetingId': meeting.id,
                  'villageId': meeting.villageId,
                  'registeredCount': meeting.totalAttendees > 0
                      ? meeting.totalAttendees
                      : 100, // fallback until village roster is wired
                },
              );
            },
            icon: const Icon(Icons.people),
            label: const Text('Manage Attendance & Quorum'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Navigate to resolution ledger
              Navigator.pushNamed(context, AppRouter.resolutionLedger, arguments: meeting.id);
            },
            icon: const Icon(Icons.gavel),
            label: const Text('Record Resolution'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(meetingsProvider.notifier).completeMeeting(meeting.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('End Meeting'),
          ),
        ],
        if (meeting.status == MeetingStatus.completed)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.resolutionLedger, arguments: meeting.id);
            },
            icon: const Icon(Icons.history),
            label: const Text('View Resolutions Ledger'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
      ],
    );
  }

  Widget _buildVillagerControls(BuildContext context, WidgetRef ref, GramSabhaMeeting meeting) {
    if (meeting.status == MeetingStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // We simulate the check-in process for the web
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulating Attendance Check-in...')),
              );
              // In a real app, this opens the camera for ML Kit and checks GPS.
            },
            icon: const Icon(Icons.how_to_reg),
            label: const Text('Self Check-In (Attendance)'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      );
    } else if (meeting.status == MeetingStatus.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.resolutionLedger, arguments: meeting.id);
            },
            icon: const Icon(Icons.history),
            label: const Text('View Resolutions Ledger'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  GramSabhaMeeting? _findMeeting(MeetingsState state, String id) {
    if (state.todayMeeting?.id == id) return state.todayMeeting;
    try {
      return state.upcomingMeetings.firstWhere((m) => m.id == id);
    } catch (_) {}
    try {
      return state.pastMeetings.firstWhere((m) => m.id == id);
    } catch (_) {}
    return null;
  }

  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.inProgress:
        return AppColors.secondary;
      case MeetingStatus.completed:
        return AppColors.primary;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }
}
