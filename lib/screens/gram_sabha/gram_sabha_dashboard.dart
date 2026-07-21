import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gram_sabha_meeting.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../core/routes/app_router.dart';

class GramSabhaDashboard extends ConsumerStatefulWidget {
  final Widget? bottomNavigationBar;
  const GramSabhaDashboard({super.key, this.bottomNavigationBar});

  @override
  ConsumerState<GramSabhaDashboard> createState() => _GramSabhaDashboardState();
}

class _GramSabhaDashboardState extends ConsumerState<GramSabhaDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetingsState = ref.watch(meetingsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?.role == UserRole.admin;

    return Scaffold(
      bottomNavigationBar: widget.bottomNavigationBar,
      appBar: AppBar(
        title: const Text('ग्रामसभा | Gram Sabha'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming (येणारी)'),
            Tab(text: 'Past (मागील)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeetingList(meetingsState.upcomingMeetings, meetingsState.todayMeeting),
          _buildMeetingList(meetingsState.pastMeetings, null),
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
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.createMeeting);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Schedule Meeting', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildMeetingList(List<GramSabhaMeeting> meetings, GramSabhaMeeting? todayMeeting) {
    final allMeetings = [...meetings];
    if (todayMeeting != null) {
      allMeetings.insert(0, todayMeeting);
    }

    if (allMeetings.isEmpty) {
      return const Center(
        child: Text('No meetings found.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allMeetings.length,
      itemBuilder: (context, index) {
        final meeting = allMeetings[index];
        final isToday = meeting.id == todayMeeting?.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isToday ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isToday ? AppColors.secondary : Colors.transparent,
              width: isToday ? 2 : 0,
            ),
          ),
          child: InkWell(
            onTap: () {
              // We'll pass the meeting ID as an argument
              Navigator.pushNamed(
                context,
                AppRouter.meetingDetail,
                arguments: meeting.id,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          meeting.type.displayNameMr,
                          style: const TextStyle(
                            fontFamily: 'NotoSansDevanagari',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(meeting.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(meeting.status)),
                        ),
                        child: Text(
                          meeting.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(meeting.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(meeting.scheduledDate),
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        meeting.venue,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.inProgress:
        return AppColors.secondary; // Green
      case MeetingStatus.completed:
        return AppColors.primary;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }
}
