import 'package:citk_connect/attendance/services/attendance_service.dart';
import 'package:citk_connect/attendance/models/class_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _batchId = "CSE_BTECH_4"; // TODO: Get from User Profile

  @override
  void initState() {
    super.initState();
    // Initialize TabController for 5 days (Mon-Fri)
    // We start on the current day (clamped between 0 and 4)
    int initialIndex = DateTime.now().weekday - 1;
    if (initialIndex < 0 || initialIndex > 4) initialIndex = 0;

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceService = ref.watch(attendanceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Weekly Schedule",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Debug button to upload data
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: "Upload Mock Data",
            onPressed: () => attendanceService.uploadMockTimetable(_batchId),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: "Mon"),
            Tab(text: "Tue"),
            Tab(text: "Wed"),
            Tab(text: "Thu"),
            Tab(text: "Fri"),
          ],
        ),
      ),
      body: StreamBuilder<Map<int, List<ClassSession>>?>(
        stream: attendanceService.streamTimetable(_batchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schedule = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: List.generate(5, (index) {
              final dayOfWeek = index + 1; // 1 = Mon
              final classes = schedule[dayOfWeek] ?? [];

              if (classes.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildClassCard(classes[i]),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(ClassSession session) {
    final isNow = _isClassNow(session);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNow
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isNow
            ? Border.all(
                color: Theme.of(context).colorScheme.primary, width: 1.5)
            : Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Time Column
          Column(
            children: [
              Text(
                TimeOfDay.fromDateTime(session.startTime).format(context),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                TimeOfDay.fromDateTime(session.endTime).format(context),
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
              width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${session.room} • ${session.professor}",
                        style: GoogleFonts.inter(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Text("No classes scheduled",
            style: GoogleFonts.inter(color: Colors.grey)),
      );

  bool _isClassNow(ClassSession session) {
    // Simple check if current time is within session start/end
    // For UI highlighting only
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = session.startTime.hour * 60 + session.startTime.minute;
    final endMin = session.endTime.hour * 60 + session.endTime.minute;
    return nowMin >= startMin && nowMin < endMin;
  }
}
