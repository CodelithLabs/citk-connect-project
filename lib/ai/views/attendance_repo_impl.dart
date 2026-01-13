import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/attendance_entry.dart';
import '../../domain/repositories/i_attendance_repo.dart';
import '../../core/contracts/i_routine_provider.dart';
import '../datasources/attendance_local_datasource.dart';
import '../models/attendance_entry_model.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_manager.dart';
import '../../features/attendance/domain/services/attendance_validation_service.dart';
import '../providers/context_provider.dart';

final attendanceRepositoryProvider = Provider<IAttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    ref.read(syncManagerProvider),
    ref.read(routineProvider),
  );
});

class AttendanceRepositoryImpl implements IAttendanceRepository {
  final AttendanceLocalDataSource _localDataSource =
      AttendanceLocalDataSource();
  final SyncQueue _syncQueue = SyncQueue();
  final SyncManager _syncManager;
  final IRoutineProvider _routineProvider;
  final AttendanceValidationService _validationService =
      AttendanceValidationService();

  AttendanceRepositoryImpl(this._syncManager, this._routineProvider);

  @override
  Future<List<AttendanceEntry>> getAttendance(
      DateTime start, DateTime end) async {
    final allEntries = await _localDataSource.getEntries();
    return allEntries.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<void> markAttendance(AttendanceEntry entry) async {
    // 0. Validate
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final todayRoutine = await _routineProvider.getTodayRoutine(userId);
      _validationService.validateEntry(entry, todayRoutine);
    }

    // 1. Convert to Model
    // Mark as not synced initially
    final model = AttendanceEntryModel.fromEntity(entry);
    final unsyncedModel = AttendanceEntryModel.fromJson({
      ...model.toJson(),
      'is_synced': false,
    });

    // 2. Save Locally (Optimistic Update)
    await _localDataSource.cacheEntry(unsyncedModel);

    // 3. Add to Sync Queue
    await _syncQueue.addOperation(SyncOperation(
      id: entry.id,
      action: SyncAction.create,
      collection: 'attendance_entries',
      payload: model.toJson(),
      timestamp: DateTime.now(),
    ));

    // 4. Trigger Sync (Fire and forget)
    _syncManager.processQueue();
  }

  @override
  Future<void> syncPendingChanges() async {
    await _syncManager.processQueue();
  }
}
