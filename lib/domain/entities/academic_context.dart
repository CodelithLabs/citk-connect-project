import 'routine_entry.dart';

class AcademicContext {
  final String userId;
  final Map<String, dynamic> profile;
  final List<RoutineEntry> routines;
  final Map<String, dynamic> attendance;
  final DateTime timestamp;
  final String? department;
  final String? semester;
  final RoutineEntry? currentClass;
  final RoutineEntry? nextClass;
  final List<RoutineEntry> todayRoutine;
  final List<String> atRiskSubjects;
  final Map<String, String>? subjectMappings;

  AcademicContext({
    required this.userId,
    required this.profile,
    required this.routines,
    required this.attendance,
    required this.timestamp,
    this.department,
    this.semester,
    this.currentClass,
    this.nextClass,
    required this.todayRoutine,
    required this.atRiskSubjects,
    this.subjectMappings,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'profile': profile,
    'routines': routines.map((e) => e.toJson()).toList(),
    'attendance': attendance,
    'timestamp': timestamp.toIso8601String(),
    'department': department,
    'semester': semester,
    'currentClass': currentClass?.toJson(),
    'nextClass': nextClass?.toJson(),
    'todayRoutine': todayRoutine.map((e) => e.toJson()).toList(),
    'atRiskSubjects': atRiskSubjects,
    'subjectMappings': subjectMappings,
  };
}