import 'package:citk_connect/mail/models/college_email.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MailRepository {
  // Dummy list of emails
  final List<CollegeEmail> _emails = [];

  // Get the list of emails
  List<CollegeEmail> getEmails() {
    return List.unmodifiable(_emails);
  }

  // Delete an email by ID
  Future<void> deleteEmail(String id) async {
    _emails.removeWhere((email) => email.id == id);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Archive an email by ID
  Future<void> archiveEmail(String id) async {
    _emails.removeWhere((email) => email.id == id);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final mailRepositoryProvider = Provider<MailRepository>((ref) {
  return MailRepository();
});
