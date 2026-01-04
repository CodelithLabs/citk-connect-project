import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Import all your Dashboards
import '../../home/views/aspirant_dashboard.dart';
import '../../admin/views/admin_dashboard.dart'; // Admin/Faculty
import '../../driver/views/driver_dashboard.dart'; // Driver
import '../../home/views/home_screen.dart'; // Student
import 'package:citk_connect/auth/views/login_screen.dart'; // Fallback


class RoleDispatcher extends ConsumerWidget {
  const RoleDispatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) return const LoginScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: StreamBuilder<DocumentSnapshot>(
        // Listen to the User's Document in Realtime
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          
          // 1. Loading State (While we fetch the role)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text("Verifying Identity...", style: TextStyle(color: Colors.white, fontSize: 12))
                ],
              ),
            );
          }

          // 2. Error State or No Data
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            // Edge Case: User logged in via Google, but Firestore doc wasn't created yet?
            // Usually Auth Service creates it. If missing, treat as Aspirant or Error.
            return const AspirantDashboard(); // Fallback
          }

          // 3. PARSE THE ROLE
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String role = data['role'] ?? 'aspirant';

          // 4. ROUTE TO DASHBOARD
          switch (role) {
            case 'student':
              return const HomeScreen(); // Your Student Portal
            case 'driver':
              return const DriverDashboard();
            case 'faculty':
            case 'admin':
              return const AdminDashboard();
            case 'aspirant':
            default:
              return const AspirantDashboard();
          }
        },
      ),
    );
  }
}