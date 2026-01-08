import 'package:citk_connect/attendance/services/attendance_service.dart';
import 'package:citk_connect/attendance/models/class_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfessorDashboard extends ConsumerWidget {
  const ProfessorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(attendanceServiceProvider);
    final batchId = "CSE_BTECH_4"; // Hardcoded for demo
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text("Faculty Dashboard",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<Map<int, List<ClassSession>>>(
        stream: service.streamTimetable(batchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final schedule = snapshot.data![today] ?? [];

          if (schedule.isEmpty) {
            return Center(
                child: Text("No classes today", style: GoogleFonts.inter()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final session = schedule[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: session.isCancelled
                    ? Colors.red.withValues(alpha: 0.1)
                    : null,
                child: ListTile(
                  title: Text(session.subject,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${TimeOfDay.fromDateTime(session.startTime).format(context)} • ${session.room}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _showEditDialog(context, ref, batchId, today, session),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String batchId,
      int day, ClassSession session) {
    final roomController = TextEditingController(text: session.room);
    bool isCancelled = session.isCancelled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Manage Class",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                    labelText: "Room Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Cancel Class"),
                subtitle: const Text("Notify students immediately"),
                value: isCancelled,
                activeTrackColor: Colors.red,
                onChanged: (val) => setState(() => isCancelled = val),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close")),
            FilledButton(
              onPressed: () {
                final updated = ClassSession(
                  id: session.id,
                  subject: session.subject,
                  room: roomController.text,
                  startTime: session.startTime,
                  endTime: session.endTime,
                  professor: session.professor,
                  isCancelled: isCancelled,
                  dayOfWeek: day,
                );

                ref
                    .read(attendanceServiceProvider)
                    .updateClassSession(batchId, day, updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Schedule updated & students notified")),
                );
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
