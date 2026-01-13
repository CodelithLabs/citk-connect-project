import '../../domain/entities/attendance_entry.dart';

abstract class IAttendanceRepository {
  /// Get attendance for a specific date range (from local cache)
  Future<List<AttendanceEntry>> getAttendance(DateTime start, DateTime end);

  /// Mark attendance (Optimistic UI: Local write + Sync Queue)
  Future<void> markAttendance(AttendanceEntry entry);

  /// Sync pending changes to backend
  Future<void> syncPendingChanges();
}
