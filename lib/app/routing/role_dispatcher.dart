import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📦 IMPORT ALL DASHBOARDS
// ═══════════════════════════════════════════════════════════════════════════
import '../../home/views/aspirant_dashboard.dart';
import '../../admin/views/admin_dashboard.dart';
import '../../driver/views/driver_dashboard.dart';
import '../../home/views/home_screen.dart';
import '../../auth/views/login_screen.dart';

// TODO: Import future role-based screens
// import '../../parent/views/parent_dashboard.dart';
// import '../../guest/views/guest_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 ROLE DISPATCHER (Smart Router based on Firestore role)
// ═══════════════════════════════════════════════════════════════════════════

class RoleDispatcher extends ConsumerStatefulWidget {
  const RoleDispatcher({super.key});

  @override
  ConsumerState<RoleDispatcher> createState() => _RoleDispatcherState();
}

class _RoleDispatcherState extends ConsumerState<RoleDispatcher> {
  // Track retry attempts for error recovery
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  // Cache for role to prevent unnecessary reads
  String? _cachedRole;
  
  // Timeout for Firestore operations
  static const Duration _firestoreTimeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _logInfo('RoleDispatcher initialized');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ───────────────────────────────────────────────────────────────────────
    // 🛡️ SAFETY CHECK: User must be authenticated
    // ───────────────────────────────────────────────────────────────────────
    if (user == null) {
      _logError('RoleDispatcher called with null user', 'User logged out');
      // This should never happen due to router guards, but handle gracefully
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
      return const _LoadingScreen(message: 'Redirecting to login...');
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🔥 FIRESTORE STREAM: Listen to user document in real-time
    // ───────────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .timeout(
              _firestoreTimeout,
              onTimeout: (sink) {
                _logError('Firestore stream timeout', 'No response in $_firestoreTimeout');
                sink.addError(TimeoutException('Firestore connection timeout'));
              },
            ),
        builder: (context, snapshot) {
          // ─────────────────────────────────────────────────────────────────
          // 1️⃣ LOADING STATE (Initial connection)
          // ─────────────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(message: 'Verifying identity...');
          }

          // ─────────────────────────────────────────────────────────────────
          // 2️⃣ ERROR STATE (Network issues, permission denied, etc.)
          // ─────────────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            _logError('Firestore stream error', snapshot.error ?? 'Unknown Firestore error');
            return _ErrorStateWidget(
              error: snapshot.error.toString(),
              onRetry: _retryCount < _maxRetries ? _handleRetry : null,
              retryCount: _retryCount,
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // 3️⃣ NO DATA / DOCUMENT DOESN'T EXIST
          // ─────────────────────────────────────────────────────────────────
          if (!snapshot.hasData || !snapshot.data!.exists) {
            _logError('User document not found', 'UID: ${user.uid}');
            return _NoUserDocumentWidget(
              userId: user.uid,
              email: user.email ?? 'Unknown',
              onCreateProfile: () => _createUserProfile(user),
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // 4️⃣ PARSE USER DATA
          // ─────────────────────────────────────────────────────────────────
          final data = (snapshot.data!.data() ?? {}) as Map<String, dynamic>;
          
          if (data == null) {
            _logError('User document data is null', 'UID: ${user.uid}');
            return _NoUserDocumentWidget(
              userId: user.uid,
              email: user.email ?? 'Unknown',
              onCreateProfile: () => _createUserProfile(user),
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // 5️⃣ EXTRACT ROLE (with fallback)
          // ─────────────────────────────────────────────────────────────────
          final String role = (data['role'] ?? 'aspirant').toString().toLowerCase().trim();
          
          // Cache the role for logging/debugging
          if (_cachedRole != role) {
            _cachedRole = role;
            _logInfo('User role resolved: $role');
          }

          // ─────────────────────────────────────────────────────────────────
          // 6️⃣ ROUTE TO APPROPRIATE DASHBOARD
          // ─────────────────────────────────────────────────────────────────
          return _routeToRoleBasedDashboard(role, data);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔀 ROLE-BASED ROUTING LOGIC
  // ═══════════════════════════════════════════════════════════════════════

  Widget _routeToRoleBasedDashboard(String role, Map<String, dynamic> userData) {
    // TODO: Add role-based analytics tracking
    // _trackRoleAccess(role);

    switch (role) {
      // ─────────────────────────────────────────────────────────────────────
      // 👨‍🎓 STUDENT ROLE
      // ─────────────────────────────────────────────────────────────────────
      case 'student':
        return const HomeScreen();

      // ─────────────────────────────────────────────────────────────────────
      // 🚗 DRIVER ROLE
      // ─────────────────────────────────────────────────────────────────────
      case 'driver':
        return const DriverDashboard();

      // ─────────────────────────────────────────────────────────────────────
      // 👨‍🏫 FACULTY ROLE
      // ─────────────────────────────────────────────────────────────────────
      case 'faculty':
      case 'teacher':
      case 'professor':
        return const AdminDashboard(); // Faculty shares admin dashboard

      // ─────────────────────────────────────────────────────────────────────
      // 🛡️ ADMIN ROLE
      // ─────────────────────────────────────────────────────────────────────
      case 'admin':
      case 'administrator':
      case 'superadmin':
        return const AdminDashboard();

      // ─────────────────────────────────────────────────────────────────────
      // 🌟 ASPIRANT ROLE (Default for new users)
      // ─────────────────────────────────────────────────────────────────────
      case 'aspirant':
      case 'applicant':
      case 'prospect':
        return const AspirantDashboard();

      // ─────────────────────────────────────────────────────────────────────
      // ❓ UNKNOWN ROLE (Fallback with warning)
      // ─────────────────────────────────────────────────────────────────────
      default:
        _logError('Unknown role detected', 'Role: $role');
        return _UnknownRoleWidget(
          role: role,
          userId: userData['uid'] ?? 'unknown',
        );
    }

    // TODO: Add more roles when implemented
    // case 'parent':
    //   return const ParentDashboard();
    // case 'guest':
    //   return const GuestDashboard();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔄 RETRY MECHANISM
  // ═══════════════════════════════════════════════════════════════════════

  void _handleRetry() {
    setState(() {
      _retryCount++;
    });
    _logInfo('Retry attempt: $_retryCount/$_maxRetries');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🛠️ CREATE USER PROFILE (Auto-fix missing documents)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _createUserProfile(User user) async {
    try {
      _logInfo('Creating missing user profile for ${user.uid}');
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'New User',
        'role': 'aspirant', // Default role
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _logInfo('User profile created successfully');
      
      // Trigger rebuild
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logError('Failed to create user profile', e);
      // TODO: Show error snackbar
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🐛 LOGGING
  // ═══════════════════════════════════════════════════════════════════════

  void _logInfo(String message) {
    if (kDebugMode) {
      developer.log('🎯 $message', name: 'ROLE_DISPATCHER');
    }
  }

  void _logError(String title, Object error) {
    if (kDebugMode) {
      developer.log('❌ $title: $error', name: 'ROLE_DISPATCHER_ERROR');
    }
    // TODO: Send to crash reporting
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 UI COMPONENTS (Loading, Error States)
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF8AB4F8),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final int retryCount;

  const _ErrorStateWidget({
    required this.error,
    required this.onRetry,
    required this.retryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 80,
              color: Color(0xFFCF6679),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              kDebugMode ? error : 'Unable to load your profile. Please check your connection.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('Retry (${retryCount + 1}/3)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black,
                ),
              )
            else
              const Text(
                'Max retries reached. Please restart the app.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoUserDocumentWidget extends StatelessWidget {
  final String userId;
  final String email;
  final VoidCallback onCreateProfile;

  const _NoUserDocumentWidget({
    required this.userId,
    required this.email,
    required this.onCreateProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: 80,
              color: Color(0xFFCF6679),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No profile found for $email',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateProfile,
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8AB4F8),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownRoleWidget extends StatelessWidget {
  final String role;
  final String userId;

  const _UnknownRoleWidget({
    required this.role,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.help_outline,
                size: 80,
                color: Color(0xFFFFAB00),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unknown Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your role "$role" is not recognized.\nPlease contact support.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Default to Aspirant Dashboard as fallback
              const AspirantDashboard(),
            ],
          ),
        ),
      ),
    );
  }
}