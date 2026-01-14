import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/ai/services/citk_ai_agent.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);

    // Auto-select current day
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Mon, 5 = Fri
    if (weekday >= 1 && weekday <= 5) {
      _tabController.index = weekday - 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(citkAgentProvider);
    // Ensure knowledge is loaded. In a real app, handle loading state properly.
    final timetable =
        agent.knowledge?.timetable['schedule'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: Text(
          'ACADEMIC SCHEDULE',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
        ),
      ),
      body: timetable == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final daySchedule = timetable[day] as Map<String, dynamic>?;
                if (daySchedule == null) {
                  return Center(
                    child: Text(
                      "No classes scheduled.",
                      style: GoogleFonts.inter(color: Colors.white38),
                    ),
                  );
                }
                return _buildDaySchedule(daySchedule);
              }).toList(),
            ),
    );
  }

  Widget _buildDaySchedule(Map<String, dynamic> daySchedule) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daySchedule.length,
      itemBuilder: (context, index) {
        final semGroup = daySchedule.keys.elementAt(index);
        final branches = daySchedule[semGroup] as Map<String, dynamic>;

        return _SemesterGroupCard(
          semGroup: semGroup,
          branches: branches,
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
      },
    );
  }
}

class _SemesterGroupCard extends StatelessWidget {
  final String semGroup;
  final Map<String, dynamic> branches;

  const _SemesterGroupCard({required this.semGroup, required this.branches});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF181B21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          semGroup.replaceAll('_', ' '),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: const Color(0xFF6C63FF),
        collapsedIconColor: Colors.white54,
        children: branches.entries.map((entry) {
          return _BranchSchedule(
            branch: entry.key,
            data: entry.value as Map<String, dynamic>,
          );
        }).toList(),
      ),
    );
  }
}

class _BranchSchedule extends StatelessWidget {
  final String branch;
  final Map<String, dynamic> data;

  const _BranchSchedule({required this.branch, required this.data});

  @override
  Widget build(BuildContext context) {
    final slots = List<String>.from(data['slots'] ?? []);
    final room = data['room'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                branch,
                style: GoogleFonts.robotoMono(
                  color: const Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Room: $room",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(slots.length, (i) {
              final slot = slots[i];
              if (slot.isEmpty) return const SizedBox.shrink();

              // Simple time estimation: 9 AM + index
              final time = "${9 + i}:00";

              return Chip(
                label: Text("$time - $slot"),
                backgroundColor: slot == "Lunch Break"
                    ? Colors.orange.withValues(alpha: 0.2)
                    : const Color(0xFF252538),
                labelStyle:
                    GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                padding: EdgeInsets.zero,
              );
            }),
          ),
        ],
      ),
    );
  }
}
