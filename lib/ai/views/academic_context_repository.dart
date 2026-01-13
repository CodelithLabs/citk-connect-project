import 'package:intl/intl.dart';
import '../../../core/contracts/i_attendance_provider.dart';
import '../../../core/contracts/i_profile_provider.dart';
import '../../../core/contracts/i_routine_provider.dart';
import '../../../domain/entities/academic_context.dart';
import '../../../domain/entities/routine_entry.dart';

class AcademicContextRepository {
  final IProfileProvider _profileProvider;
  final IRoutineProvider _routineProvider;
  final IAttendanceProvider _attendanceProvider;

  AcademicContextRepository({
    required IProfileProvider profileProvider,
    required IRoutineProvider routineProvider,
    required IAttendanceProvider attendanceProvider,
  })  : _profileProvider = profileProvider,
        _routineProvider = routineProvider,
        _attendanceProvider = attendanceProvider;

  Future<AcademicContext> buildAcademicContext(String userId) async {
    final profile = await _profileProvider.getProfile(userId) ?? {};
    final routineList = await _routineProvider.getRoutines(userId);
    final attendance = await _attendanceProvider.getAttendance(userId);

    // 1. Calculate the dynamic academic state
    final state = _calculateAcademicState(routineList);

    return AcademicContext(
      userId: userId,
      profile: profile,
      routines: routineList,
      attendance: attendance,
      timestamp: DateTime.now(),
      department: profile['department'] as String?,
      semester: profile['semester'] as String?,

      // 2. Inject the calculated state
      todayRoutine: state['todayRoutine'] as List<RoutineEntry>,
      currentClass: state['currentClass'] as RoutineEntry?,
      nextClass: state['nextClass'] as RoutineEntry?,
      atRiskSubjects: [], // Implement your attendance logic here
    );
  }

  /// Helper to filter routines based on current Day and Time
  Map<String, dynamic> _calculateAcademicState(List<RoutineEntry> allRoutines) {
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now); // e.g., "Monday"

    // Filter for today
    final todayRoutine = allRoutines
        .where((r) => r.day.toLowerCase() == todayName.toLowerCase())
        .toList();

    // Sort by start time (assuming HH:mm 24-hour format or consistent string)
    todayRoutine.sort((a, b) => a.startTime.compareTo(b.startTime));

    RoutineEntry? current;
    RoutineEntry? next;

    // Simple time logic (You may need more robust parsing depending on your string format)
    final currentTimeStr = DateFormat('HH:mm').format(now);

    for (var i = 0; i < todayRoutine.length; i++) {
      final entry = todayRoutine[i];
      if (currentTimeStr.compareTo(entry.startTime) >= 0 &&
          currentTimeStr.compareTo(entry.endTime) <= 0) {
        current = entry;
        if (i + 1 < todayRoutine.length) next = todayRoutine[i + 1];
        break;
      }

      if (currentTimeStr.compareTo(entry.startTime) < 0) {
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
}
