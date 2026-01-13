import '../../../core/contracts/i_attendance_provider.dart';
import '../../../core/contracts/i_profile_provider.dart';
import '../../../core/contracts/i_routine_provider.dart';
import '../../../domain/entities/academic_context.dart';
import '../../../domain/entities/routine_entry.dart';
import '../../../features/attendance/services/attendance_calculation_service.dart';

class AcademicContextRepository {
  final IProfileProvider _profileProvider;
  final IRoutineProvider _routineProvider;
  final IAttendanceProvider _attendanceProvider;
  final AttendanceCalculationService _calculationService =
      AttendanceCalculationService();

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
    final state = _calculationService.calculateAcademicState(routineList);

    // 2. Calculate At Risk Subjects (< 75%)
    final atRiskSubjects =
        _calculationService.calculateAtRiskSubjects(attendance);

    // 3. Build Subject Mappings
    final subjectMappings = <String, String>{};
    for (final r in routineList) {
      if (r.subjectCode.isNotEmpty && r.subjectName.isNotEmpty) {
        subjectMappings[r.subjectCode] = r.subjectName;
      }
    }

    return AcademicContext(
      userId: userId,
      profile: profile,
      routines: routineList,
      attendance: attendance,
      timestamp: DateTime.now(),
      department: profile['department']?.toString(),
      semester: profile['semester']?.toString(),

      // 4. Inject the calculated state
      todayRoutine: state['todayRoutine'] as List<RoutineEntry>,
      currentClass: state['currentClass'] as RoutineEntry?,
      nextClass: state['nextClass'] as RoutineEntry?,
      atRiskSubjects: atRiskSubjects,
      subjectMappings: subjectMappings,
    );
  }
}
