import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FloatingRoleToggle extends StatelessWidget {
  const FloatingRoleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'role_toggle_fab',
      tooltip: 'Debug: Switch Role',
      backgroundColor: const Color(0xFF6C63FF), // Gen Z Periwinkle
      elevation: 4,
      onPressed: () => _toggleRole(context),
      child: const Icon(Icons.swap_horiz, color: Colors.white),
    );
  }

  Future<void> _toggleRole(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack(context, 'No user logged in');
      return;
    }

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        _showSnack(context, 'User profile not found');
        return;
      }

      final currentRole = (doc.data()?['role'] ?? 'student').toString();
      final nextRole = _getNextRole(currentRole);

      await userRef.update({'role': nextRole});

      if (context.mounted) {
        _showSnack(context, 'Switched to ${nextRole.toUpperCase()}');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Error: $e');
      }
    }
  }

  String _getNextRole(String current) {
    const roles = ['student', 'faculty', 'driver', 'aspirant'];
    final index = roles.indexOf(current.toLowerCase());
    if (index == -1) return 'student';
    return roles[(index + 1) % roles.length];
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
