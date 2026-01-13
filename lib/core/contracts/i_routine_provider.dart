import '../../domain/entities/routine_entry.dart';

abstract class IRoutineProvider {
  Future<List<RoutineEntry>> getRoutines(String userId);
  Future<List<RoutineEntry>> getTodayRoutine(String userId);
  Future<RoutineEntry?> getCurrentClass(String userId);
  Future<RoutineEntry?> getRoutineById(String userId, String routineId);
  Future<void> saveRoutine(String userId, RoutineEntry routine);
}
