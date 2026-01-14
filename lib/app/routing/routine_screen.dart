// lib/routine/views/routine_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/routine/views/widgets/weekly_schedule_grid.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class ClassSession {
  final String id;
  final String subject;
  final String startTime;
  final String endTime;
  final String room;
  final String day;

  ClassSession({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.day,
  });
}

final routineProvider =
    StateNotifierProvider<RoutineNotifier, List<ClassSession>>((ref) {
  return RoutineNotifier();
});

class RoutineNotifier extends StateNotifier<List<ClassSession>> {
  RoutineNotifier() : super([]);

  void addSession(ClassSession session) => state = [...state, session];
  void deleteSession(String id) =>
      state = state.where((s) => s.id != id).toList();
}

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  bool _isWeeklyView = false;
  final GlobalKey _exportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final routine = ref.watch(routineProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Class Routine',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isWeeklyView
                ? Icons.view_day_outlined
                : Icons.calendar_view_week_outlined),
            tooltip: _isWeeklyView ? 'Daily View' : 'Weekly View',
            onPressed: () => setState(() => _isWeeklyView = !_isWeeklyView),
          ),
          if (_isWeeklyView)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Export Schedule',
              onPressed: _exportSchedule,
            ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Attendance Calculator',
            onPressed: () => _showAttendanceCalculator(context),
          ),
        ],
        bottom: _isWeeklyView
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                tabs: _days.map((day) => Tab(text: day)).toList(),
              ),
      ),
      body: _isWeeklyView
          ? WeeklyScheduleGrid(sessions: routine, exportKey: _exportKey)
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) => _buildDayView(day, isDark)).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context),
        label: const Text('Add Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayView(String day, bool isDark) {
    final routine = ref.watch(routineProvider);
    final dayClasses = routine.where((c) => c.day == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayClasses.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dayClasses.length,
        itemBuilder: (context, index) {
          final session = dayClasses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.startTime,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
              title: Text(session.subject,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('${session.room} • ${session.endTime}',
                  style: GoogleFonts.inter(color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => ref
                    .read(routineProvider.notifier)
                    .deleteSession(session.id),
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX();
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No classes for $day',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    String selectedDay = _days[_tabController.index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDay,
                items: _days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => selectedDay = v!,
                decoration: const InputDecoration(labelText: 'Day'),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject')),
              const SizedBox(height: 8),
              TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Start Time (e.g. 09:00)')),
              const SizedBox(height: 8),
              TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                      labelText: 'End Time (e.g. 10:00)')),
              const SizedBox(height: 8),
              TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (subjectCtrl.text.isNotEmpty && startCtrl.text.isNotEmpty) {
                ref.read(routineProvider.notifier).addSession(ClassSession(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      subject: subjectCtrl.text,
                      startTime: startCtrl.text,
                      endTime: endCtrl.text,
                      room: roomCtrl.text,
                      day: selectedDay,
                    ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceCalculator(BuildContext context) {
    final totalCtrl = TextEditingController();
    final attendedCtrl = TextEditingController();
    String result = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Calculator',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Total Classes Held',
                    prefixIcon: Icon(Icons.class_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: attendedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Classes Attended',
                    prefixIcon: Icon(Icons.check_circle_outline)),
              ),
              const SizedBox(height: 20),
              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(result,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final total = int.tryParse(totalCtrl.text) ?? 0;
                    final attended = int.tryParse(attendedCtrl.text) ?? 0;
                    if (total == 0) return;

                    final pct = (attended / total) * 100;
                    String msg =
                        'Current Attendance: ${pct.toStringAsFixed(1)}%\n';

                    if (pct < 75) {
                      final required = (3 * total - 4 * attended).ceil();
                      msg +=
                          'You need to attend the next $required classes to reach 75%.';
                    } else {
                      final bunkable = ((4 * attended - 3 * total) / 3).floor();
                      msg +=
                          'You can safely skip $bunkable classes and stay above 75%.';
                    }
                    setState(() => result = msg);
                  },
                  child: const Text('Calculate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSchedule() async {
    try {
      final boundary = _exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/schedule.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'My Class Routine');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
