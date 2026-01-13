import 'package:flutter/foundation.dart';

enum AttendanceStatus { present, absent, late, excused }

enum ClassType { lecture, lab, tutorial }

@immutable
class AttendanceEntry {
  final String id;
  final String subjectId;
  final DateTime timestamp;
  final AttendanceStatus status;
  final ClassType type;
  final String semesterId;
  final String? notes;
  final DateTime createdAt;
  final bool isSynced;

  const AttendanceEntry({
    required this.id,
    required this.subjectId,
    required this.timestamp,
    required this.status,
    required this.type,
    required this.semesterId,
    this.notes,
    required this.createdAt,
    this.isSynced = true,
  });

  // Helper to check if entry is for a specific date
  bool isForDate(DateTime date) {
    return timestamp.year == date.year &&
        timestamp.month == date.month &&
        timestamp.day == date.day;
  }
}
