import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final roleServiceProvider = StreamProvider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // Listen to the user's role in real-time
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        
        final data = doc.data();
        final role = data?['role'] as String?;
        
        // 💾 CACHE: Update local storage for offline access
        if (role != null) {
          SharedPreferences.getInstance().then((prefs) => prefs.setString('user_role', role));
        }
        
        return role;
      });
});