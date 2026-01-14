import 'package:flutter_riverpod/flutter_riverpod.dart';

final mailActionServiceProvider = Provider<MailActionService>((ref) {
  return MailActionService();
});

class MailActionService {
  Future<void> archiveEmail(String id) async {
    // Mock network delay
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> deleteEmail(String id) async {
    // Mock network delay
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> sendEmail(String to, String subject, String body) async {
    // Mock network delay
    await Future.delayed(const Duration(seconds: 2));
  }
}
