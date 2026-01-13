import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class FirestoreSeeder {
  /// Seeds the 'notices' collection with dummy data for testing.
  static Future<void> seedNotices() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final List<Map<String, dynamic>> dummyNotices = [
      {
        'title': 'Semester Exams Postponed',
        'content': 'Due to unforeseen circumstances, the exams scheduled for Monday are postponed.',
        'date': Timestamp.now(),
        'author': 'Dean Academic',
        'type': 'academic',
        'isImportant': true,
      },
      {
        'title': 'Tech Fest 2024 Registration',
        'content': 'Register now for the upcoming Tech Fest. Visit the student council office.',
        'date': Timestamp.now(),
        'author': 'Student Council',
        'type': 'event',
        'isImportant': false,
      },
      {
        'title': 'Library Maintenance',
        'content': 'The central library will remain closed on Sunday for maintenance.',
        'date': Timestamp.now(),
        'author': 'Librarian',
        'type': 'general',
        'isImportant': false,
      },
    ];

    for (var notice in dummyNotices) {
      final docRef = firestore.collection('notices').doc();
      batch.set(docRef, notice);
    }

    try {
      await batch.commit();
      developer.log('✅ Firestore seeded with ${dummyNotices.length} notices.', name: 'SEEDER');
    } catch (e) {
      developer.log('❌ Failed to seed Firestore: $e', name: 'SEEDER');
    }
  }
}
