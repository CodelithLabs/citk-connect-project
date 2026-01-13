import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../attendance/providers/attendance_provider.dart';

class SmartAttendanceCard extends ConsumerWidget {
  const SmartAttendanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF303F9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: attendanceAsync.when(
                    data: (data) => data.percentage / 100,
                    loading: () => 0,
                    error: (_, __) => 0,
                  ),
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                Text(
                  attendanceAsync.when(
                    data: (data) => "${data.percentage.toStringAsFixed(0)}%",
                    loading: () => "--",
                    error: (_, __) => "ERR",
                  ),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Status",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  attendanceAsync.when(
                    data: (data) => "You are ${data.status}! 🛡️",
                    loading: () => "Loading...",
                    error: (_, __) => "Unavailable",
                  ),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep it up!",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }
}
