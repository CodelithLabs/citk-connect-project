import 'package:flutter_riverpod/flutter_riverpod.dart';
// FIX: Ensure this path matches your folder structure
import '../data/repositories/academic_context_repository.dart';
import '../services/firebase_context_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore Instance
final firebaseFirestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Providers for the sources (Profile, Routine, Attendance)
// Assuming you have these providers defined elsewhere or locally:
final profileProvider = Provider(
    (ref) => FirebaseProfileProvider(ref.read(firebaseFirestoreProvider)));
final routineProvider = Provider(
    (ref) => FirebaseRoutineProvider(ref.read(firebaseFirestoreProvider)));
final attendanceProvider = Provider(
    (ref) => FirebaseAttendanceProvider(ref.read(firebaseFirestoreProvider)));

// The Repository Provider
final academicContextRepositoryProvider =
    Provider<AcademicContextRepository>((ref) {
  return AcademicContextRepository(
    profileProvider: ref.watch(profileProvider),
    routineProvider: ref.watch(routineProvider),
    attendanceProvider: ref.watch(attendanceProvider),
  );
});
