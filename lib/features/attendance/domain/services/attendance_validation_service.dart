import '../../../../domain/entities/attendance_entry.dart';
import '../../../../domain/entities/routine_entry.dart';

class AttendanceValidationException implements Exception {
  final String message;
  AttendanceValidationException(this.message);
  @override
  String toString() => message;
}

class AttendanceValidationService {
  void validateEntry(AttendanceEntry entry, List<RoutineEntry> todayRoutine) {
    // 1. Future Check
    if (entry.timestamp.isAfter(DateTime.now())) {
      throw AttendanceValidationException(
          "Cannot mark attendance for future classes.");
    }

    // 2. Routine Check
    final isScheduled =
        todayRoutine.any((r) => r.subjectCode == entry.subjectId);
    if (!isScheduled) {
      // Warning: This subject is not in the routine.
      // We allow it for now (e.g. extra class), but could throw exception if strict.
    }
  }
}
