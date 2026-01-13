abstract class IAttendanceProvider {
  Future<Map<String, dynamic>> getAttendance(String userId);
  Future<Map<String, dynamic>> getAttendancePercentages(String userId);
  Future<void> updateAttendance(String userId, Map<String, dynamic> attendance);
}