import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/views/attendance_repo_impl.dart';
import '../../domain/entities/attendance_entry.dart';

class AttendanceSummary {
  final double percentage;
  final String status;

  AttendanceSummary({required this.percentage, required this.status});
}

final attendanceProvider = FutureProvider<AttendanceSummary>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final now = DateTime.now();
  // Fetch last 30 days for summary
  final start = now.subtract(const Duration(days: 30));
  final end = now;
  
  final entries = await repo.getAttendance(start, end);

  if (entries.isEmpty) {
    return AttendanceSummary(percentage: 100.0, status: 'No Data');
  }

  final present = entries.where((e) => e.status == AttendanceStatus.present).length;
  final total = entries.length;
  final percentage = (present / total) * 100;

  return AttendanceSummary(
    percentage: percentage,
    status: percentage >= 75 ? 'Safe' : 'At Risk',
  );
});
