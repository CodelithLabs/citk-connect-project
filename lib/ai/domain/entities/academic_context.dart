class AcademicContext {
  final String userId;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> routines;
  final Map<String, dynamic> attendance;
  final DateTime timestamp;
  final String? department;
  final String? semester;
  final Map<String, dynamic>? currentClass;
  final Map<String, dynamic>? nextClass;
  final List<Map<String, dynamic>>? todayRoutine;
  final List<String>? atRiskSubjects;
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
    this.todayRoutine,
    this.atRiskSubjects,
    this.subjectMappings,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'profile': profile,
    'routines': routines,
    'attendance': attendance,
    'timestamp': timestamp.toIso8601String(),
    'department': department,
    'semester': semester,
    'currentClass': currentClass,
    'nextClass': nextClass,
    'todayRoutine': todayRoutine,
    'atRiskSubjects': atRiskSubjects,
    'subjectMappings': subjectMappings,
  };
}