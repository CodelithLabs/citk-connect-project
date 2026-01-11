import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionServiceProvider = StreamProvider<List<String>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return [];

    final data = doc.data();
    final List<dynamic> perms = data?['permissions'] ?? [];
    final permissions = perms.cast<String>().toList();

    // Admin wildcard
    if (data?['role'] == 'admin' && !permissions.contains('*')) {
      permissions.add('*');
    }

    return permissions;
  });
});

extension PermissionCheck on List<String> {
  bool hasPermission(String permission) {
    if (contains('*')) return true;
    return contains(permission);
  }

  bool get isAdmin => hasPermission('*') || hasPermission('manage_users');
  bool get canPostNotice => hasPermission('post_notice');
  bool get canDrive => hasPermission('broadcast_location');
}
