import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_entry.dart';

class AttendanceEntryModel extends AttendanceEntry {
  const AttendanceEntryModel({
    required super.id,
    required super.subjectId,
    required super.timestamp,
    required super.status,
    required super.type,
    required super.semesterId,
    super.notes,
    required super.createdAt,
    super.isSynced,
  });

  factory AttendanceEntryModel.fromEntity(AttendanceEntry entry) {
    return AttendanceEntryModel(
      id: entry.id,
      subjectId: entry.subjectId,
      timestamp: entry.timestamp,
      status: entry.status,
      type: entry.type,
      semesterId: entry.semesterId,
      notes: entry.notes,
      createdAt: entry.createdAt,
      isSynced: entry.isSynced,
    );
  }

  factory AttendanceEntryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEntryModel(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      timestamp: (json['timestamp'] is Timestamp)
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] as String),
      status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.present),
      type: ClassType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => ClassType.lecture),
      semesterId: json['semester_id'] as String,
      notes: json['notes'] as String?,
      createdAt: (json['created_at'] is Timestamp)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.parse(json['created_at'] as String),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'type': type.name,
      'semester_id': semesterId,
      'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AttendanceEntry toEntity() {
    return this;
  }
}
