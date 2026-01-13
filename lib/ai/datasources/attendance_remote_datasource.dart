import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_entry_model.dart';

class AttendanceRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadEntry(AttendanceEntryModel entry) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance_entries')
        .doc(entry.id)
        .set(entry.toJson());
  }

  // Add fetch methods here for initial sync
}
