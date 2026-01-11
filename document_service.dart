import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

final documentServiceProvider = Provider((ref) => DocumentService());

class DocumentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadDocument(File file, String customName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Create a unique filename
    final extension = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$extension';
    
    // Reference: users/{uid}/documents/{timestamp_ext}
    final storageRef = _storage.ref().child('users/${user.uid}/documents/$fileName');
    
    // 1. Upload File
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    // 2. Save Metadata to Firestore
    await _db.collection('users').doc(user.uid).collection('documents').add({
      'name': customName.isNotEmpty ? customName : path.basenameWithoutExtension(file.path),
      'url': downloadUrl,
      'fileName': fileName,
      'type': extension.replaceAll('.', '').toUpperCase(),
      'uploadedAt': FieldValue.serverTimestamp(),
      'size': await file.length(),
      'source': 'SBI Collect/Web',
    });
  }
}