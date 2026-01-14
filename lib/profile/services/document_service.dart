import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

final documentServiceProvider = Provider((ref) => DocumentService());

class DocumentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadDocument() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);

    // Create a unique filename
    final extension = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';

    // Reference: users/{uid}/documents/{timestamp_ext}
    final storageRef =
        _storage.ref().child('users/${user.uid}/documents/$fileName');

    // 1. Upload File
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    // 2. Save Metadata to Firestore
    await _db.collection('users').doc(user.uid).collection('documents').add({
      'name': path.basenameWithoutExtension(file.path),
      'url': downloadUrl,
      'fileName': fileName,
      'type': extension.replaceAll('.', '').toUpperCase(),
      'uploadedAt': FieldValue.serverTimestamp(),
      'size': await file.length(),
      'source': 'manual_upload',
    });
  }

  Stream<QuerySnapshot> getUserDocuments() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteDocument(String docId, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Delete from Storage (Best effort)
    try {
      await _storage.ref().child('users/${user.uid}/documents/$fileName').delete();
    } catch (_) {}

    // 2. Delete Metadata from Firestore
    await _db.collection('users').doc(user.uid).collection('documents').doc(docId).delete();
  }
}
