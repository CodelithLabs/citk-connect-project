// 📦 FILE: lib/attendance/models/class_session.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSession {
  final String id;
  final String subject;
  final String professor;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final int dayOfWeek; // 1 = Mon, 7 = Sun
  final bool isCancelled;

  ClassSession({
    required this.id,
    required this.subject,
    required this.professor,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.isCancelled = false,
  });

  // Factory to create object from Firestore data
  factory ClassSession.fromMap(Map<String, dynamic> data, String id) {
    return ClassSession(
      id: id,
      subject: data['subject'] ?? 'Unknown Subject',
      professor: data['professor'] ?? 'TBA',
      room: data['room'] ?? 'TBA',
      // Handle Firestore Timestamp to DateTime conversion safely
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      dayOfWeek: data['dayOfWeek'] ?? 1,
      isCancelled: data['isCancelled'] ?? false,
    );
  }

  // Convert object to Map for uploading to Firestore
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'professor': professor,
      'room': room,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'dayOfWeek': dayOfWeek,
      'isCancelled': isCancelled,
    };
  }
}