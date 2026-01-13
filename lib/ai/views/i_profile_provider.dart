class StudentProfile {
  final String department;
  final int semester;
  final String batch;
  final String name;

  StudentProfile({
    required this.department,
    required this.semester,
    required this.batch,
    required this.name,
  });
}

abstract class IProfileProvider {
  Future<StudentProfile> getStudentProfile(String userId);
}