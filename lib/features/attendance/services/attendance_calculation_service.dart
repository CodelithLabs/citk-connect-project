import 'package:intl/intl.dart';
import '../../../domain/entities/routine_entry.dart';

class AttendanceCalculationService {
  double calculatePercentage(int present, int total) {
    if (total == 0) return 0;
    return (present / total) * 100;
  }

  bool isEligible(double percentage, {double minRequired = 75}) {
    return percentage >= minRequired;
  }

  /// Calculates the current academic state (Current Class, Next Class, Today's Routine)
  Map<String, dynamic> calculateAcademicState(List<RoutineEntry> allRoutines) {
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now);

    // Filter for today
    final todayRoutine = allRoutines
        .where((r) => r.day.toLowerCase() == todayName.toLowerCase())
        .toList();

    // Sort by start time
    todayRoutine.sort((a, b) => _compareTimes(a.startTime, b.startTime));

    RoutineEntry? current;
    RoutineEntry? next;

    final currentMinutes = now.hour * 60 + now.minute;

    for (var i = 0; i < todayRoutine.length; i++) {
      final entry = todayRoutine[i];
      final startMinutes = _parseTime(entry.startTime);
      final endMinutes = _parseTime(entry.endTime);

      if (startMinutes == -1 || endMinutes == -1) continue;

      // Check if current time is within entry start/end
      if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
        current = entry;
        if (i + 1 < todayRoutine.length) next = todayRoutine[i + 1];
        break;
      }

      if (currentMinutes < startMinutes) {
        next = entry;
        break;
      }
    }

    return {
      'todayRoutine': todayRoutine,
      'currentClass': current,
      'nextClass': next,
    };
  }

  /// Identifies subjects with attendance below the threshold
  List<String> calculateAtRiskSubjects(Map<String, dynamic> attendance,
      {double threshold = 75.0}) {
    final atRiskSubjects = <String>[];
    attendance.forEach((subject, value) {
      if (value is num && value < threshold) {
        atRiskSubjects.add(subject);
      } else if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null && parsed < threshold) {
          atRiskSubjects.add(subject);
        }
      }
    });
    return atRiskSubjects;
  }

  int _parseTime(String time) {
    try {
      final parts = time.trim().split(':');
      if (parts.length < 2) return -1;
      return int.parse(parts[0]) * 60 + int.parse(parts[1].substring(0, 2));
    } catch (_) {
      return -1;
    }
  }

  int _compareTimes(String t1, String t2) =>
      _parseTime(t1).compareTo(_parseTime(t2));
}
