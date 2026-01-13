abstract class IAttendanceProvider {
  /// Returns map of SubjectCode -> Percentage (e.g., {"CS501": 85.5})
  Future<Map<String, double>> getAttendancePercentages(String studentId);
}