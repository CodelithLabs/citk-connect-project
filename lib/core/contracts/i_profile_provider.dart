abstract class IProfileProvider {
  Future<Map<String, dynamic>?> getProfile(String userId);
  Future<Map<String, dynamic>?> getStudentProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> profile);
}