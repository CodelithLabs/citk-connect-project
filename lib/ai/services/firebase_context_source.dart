import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/routine_entry.dart';
import '../../core/contracts/i_attendance_provider.dart';
import '../../core/contracts/i_profile_provider.dart';
import '../../core/contracts/i_routine_provider.dart';

class FirebaseProfileProvider implements IProfileProvider {
  final FirebaseFirestore _firestore;

  FirebaseProfileProvider(this._firestore);

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('students').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getStudentProfile(String userId) async {
    return getProfile(userId);
  }

  @override
  Future<void> updateProfile(
      String userId, Map<String, dynamic> profile) async {
    await _firestore.collection('students').doc(userId).set(
          profile,
          SetOptions(merge: true),
        );
  }
}

class FirebaseRoutineProvider implements IRoutineProvider {
  final FirebaseFirestore _firestore;

  FirebaseRoutineProvider(this._firestore);

  @override
  Future<List<RoutineEntry>> getRoutines(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .doc(userId)
          .collection('routines')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RoutineEntry(
          id: doc.id,
          subjectCode: data['subjectCode'] ?? '',
          subjectName: data['subjectName'] ?? '',
          day: data['day'] ?? '',
          startTime: data['startTime'] ?? '',
          endTime: data['endTime'] ?? '',
          room: data['room'] ?? '',
          teacher: data['teacher'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting routines: $e');
      return [];
    }
  }

  @override
  Future<List<RoutineEntry>> getTodayRoutine(String userId) async {
    final allRoutines = await getRoutines(userId);
    final today = _getDayName(DateTime.now().weekday);
    return allRoutines.where((r) => r.day == today).toList();
  }

  @override
  Future<RoutineEntry?> getCurrentClass(String userId) async {
    final todayRoutines = await getTodayRoutine(userId);
    final now = TimeOfDay.now();

    for (final routine in todayRoutines) {
      final start = _parseTime(routine.startTime);
      final end = _parseTime(routine.endTime);

      if (_isTimeBetween(now, start, end)) {
        return routine;
      }
    }
    return null;
  }

  @override
  Future<RoutineEntry?> getRoutineById(String userId, String routineId) async {
    try {
      final doc = await _firestore
          .collection('students')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return RoutineEntry(
        id: doc.id,
        subjectCode: data['subjectCode'] ?? '',
        subjectName: data['subjectName'] ?? '',
        day: data['day'] ?? '',
        startTime: data['startTime'] ?? '',
        endTime: data['endTime'] ?? '',
        room: data['room'] ?? '',
        teacher: data['teacher'] ?? '',
      );
    } catch (e) {
      print('Error getting routine: $e');
      return null;
    }
  }

  @override
  Future<void> saveRoutine(String userId, RoutineEntry routine) async {
    await _firestore
        .collection('students')
        .doc(userId)
        .collection('routines')
        .doc(routine.id)
        .set(routine.toJson());
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay check, TimeOfDay start, TimeOfDay end) {
    final checkMinutes = check.hour * 60 + check.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
  }
}

class FirebaseAttendanceProvider implements IAttendanceProvider {
  final FirebaseFirestore _firestore;

  FirebaseAttendanceProvider(this._firestore);

  @override
  Future<Map<String, dynamic>> getAttendance(String userId) async {
    try {
      final doc = await _firestore
          .collection('students')
          .doc(userId)
          .collection('attendance')
          .doc('current')
          .get();

      return doc.exists ? doc.data()! : {};
    } catch (e) {
      print('Error getting attendance: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendancePercentages(String userId) async {
    return getAttendance(userId);
  }

  @override
  Future<void> updateAttendance(
      String userId, Map<String, dynamic> attendance) async {
    await _firestore
        .collection('students')
        .doc(userId)
        .collection('attendance')
        .doc('current')
        .set(attendance, SetOptions(merge: true));
  }
}
