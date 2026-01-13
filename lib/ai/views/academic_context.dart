import 'routine_entry.dart';

class AcademicContext {
  final String department;
  final int semester;
  final RoutineEntry? currentClass;
  final RoutineEntry? nextClass;
  final List<RoutineEntry> todayRoutine;
  final List<String> atRiskSubjects;
  final Map<String, String> subjectMappings;

  AcademicContext({
    required this.department,
    required this.semester,
    this.currentClass,
    this.nextClass,
    required this.todayRoutine,
    required this.atRiskSubjects,
    required this.subjectMappings,
  });
}