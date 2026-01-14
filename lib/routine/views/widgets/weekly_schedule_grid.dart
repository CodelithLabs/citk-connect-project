// lib/routine/views/widgets/weekly_schedule_grid.dart

import 'package:citk_connect/app/routing/routine_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyScheduleGrid extends StatelessWidget {
  final List<ClassSession> sessions;
  final GlobalKey? exportKey;

  const WeeklyScheduleGrid({super.key, required this.sessions, this.exportKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    // Generate time slots (9 AM to 5 PM)
    final timeSlots = List.generate(9, (index) => index + 9); // 9 to 17

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: RepaintBoundary(
          key: exportKey,
          child: Container(
            color: isDark ? const Color(0xFF0F1115) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Days)
                Row(
                  children: [
                    const SizedBox(width: 60), // Time column width
                    ...days.map((day) => Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                          child: Text(
                            day,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )),
                  ],
                ),
                // Time Slots
                ...timeSlots.map((hour) {
                  return Row(
                    children: [
                      // Time Label
                      Container(
                        width: 60,
                        height: 80, // Fixed height for slot
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      // Day Columns for this time slot
                      ...days.map((day) {
                        // Find class for this day and hour
                        final session = sessions.firstWhere(
                          (s) {
                            if (s.day != day) return false;
                            // Simple parsing: assumes "HH:mm" format
                            final startHour =
                                int.tryParse(s.startTime.split(':')[0]) ?? 0;
                            return startHour == hour;
                          },
                          orElse: () => ClassSession(
                              id: '',
                              subject: '',
                              startTime: '',
                              endTime: '',
                              room: '',
                              day: ''),
                        );

                        return Container(
                          width: 100,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                              width: 0.5,
                            ),
                          ),
                          child: session.id.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        session.subject,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      Text(
                                        session.room,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: theme
                                              .colorScheme.onPrimaryContainer
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
