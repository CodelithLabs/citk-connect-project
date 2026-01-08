// lib/app/routing/role_dispatcher.dart
// Production-Ready Role Dispatcher - All Compilation Errors Fixed

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citk_connect/app/config/env_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📦 IMPORT ALL DASHBOARDS
// ═══════════════════════════════════════════════════════════════════════════
import '../../home/views/aspirant_dashboard.dart';
import '../../admin/views/admin_dashboard.dart';
import '../../driver/views/driver_dashboard.dart';
import '../../home/views/home_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📊 ERROR TYPES ENUM (MUST BE TOP-LEVEL - NOT INSIDE CLASS)
// ═══════════════════════════════════════════════════════════════════════════

enum ErrorType {
  timeout,
  networkFailure,
  permissionDenied,
  documentNotFound,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 ROLE DISPATCHER (Rebuilt for Stability & SOLID Principles)
// ═══════════════════════════════════════════════════════════════════════════

class RoleDispatcher extends ConsumerStatefulWidget {
  const RoleDispatcher({super.key});

  // ✅ Timeout protection (15 seconds)
  static const Duration _timeoutDuration = Duration(seconds: 15);
  
  // ✅ Retry mechanism with exponential backoff
  static const int _maxRetryAttempts = 3;

  @override
  ConsumerState<RoleDispatcher> createState() => _RoleDispatcherState();
}

class _RoleDispatcherState extends ConsumerState<RoleDispatcher> {
  Stream<DocumentSnapshot>? _userStream;
  int _retryCount = 0;
  bool _isOfflineMode = false;
  String? _cachedRole;
  Timer? _retryTimer;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadCachedRole();
    _initStream();
    _logInfo('RoleDispatcher initialized');
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 💾 CACHING & INIT
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _cachedRole = prefs.getString('user_role');
        });
      }
    } catch (e) {
      _logError('Failed to load cached role', e);
    }
  }

  Future<void> _updateCache(String role) async {
    if (_cachedRole == role) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      if (mounted) {
        setState(() {
          _cachedRole = role;
        });
      }
    } catch (e) {
      _logError('Failed to update role cache', e);
    }
  }

  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .timeout(RoleDispatcher._timeoutDuration);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔄 RETRY & RECOVERY LOGIC
  // ═══════════════════════════════════════════════════════════════════════

  void _scheduleRetry() {
    if (_isRetrying) return;
    
    _isRetrying = true;
    final delaySeconds = math.pow(2, _retryCount).toInt(); // 1, 2, 4
    final delay = Duration(seconds: delaySeconds);
    
    _logInfo('Scheduling retry ${_retryCount + 1}/${RoleDispatcher._maxRetryAttempts} in ${delay.inSeconds}s');

    _retryTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _retryCount++;
          _isRetrying = false;
          _initStream(); // Re-initialize stream to reset timeout
        });
      }
    });
  }

  void _manualRetry() {
    _retryTimer?.cancel();
    setState(() {
      _retryCount = 0;
      _isRetrying = false;
      _isOfflineMode = false;
      _initStream();
    });
  }

  void _enterOfflineMode() {
    if (_cachedRole != null) {
      setState(() {
        _isOfflineMode = true;
      });
      _logInfo('Entered offline mode with role: $_cachedRole');
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ───────────────────────────────────────────────────────────────────────
    // 🛡️ SAFETY CHECK: User must be authenticated
    // ───────────────────────────────────────────────────────────────────────
    if (user == null) {
      // Use WidgetsBinding to avoid calling context during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      
      return const _LoadingScreen(message: 'Session expired...');
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🌐 OFFLINE MODE: Use cached role if enabled
    // ───────────────────────────────────────────────────────────────────────
    if (_isOfflineMode && _cachedRole != null) {
      return _OfflineWrapper(
        onRetry: _manualRetry,
        child: _routeToRoleBasedDashboard(_cachedRole!),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🔥 FIRESTORE STREAM: Fetch user role with error recovery
    // ───────────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          // ─────────────────────────────────────────────────────────────────
          // 1️⃣ LOADING STATE
          // ─────────────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingScreen(
              message: _retryCount > 0 
                  ? 'Retrying connection (${_retryCount}/${RoleDispatcher._maxRetryAttempts})...' 
                  : 'Loading your profile...',
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // 2️⃣ ERROR STATE (With intelligent error handling)
          // ─────────────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            // Check if we should auto-retry
            if (_retryCount < RoleDispatcher._maxRetryAttempts) {
              // Schedule retry if not already scheduled
              _scheduleRetry();
              return _LoadingScreen(
                message: 'Connection unstable. Retrying in ${math.pow(2, _retryCount)}s...',
              );
            }
            
            return _handleStreamError(snapshot.error!, user.uid);
          }

          // ─────────────────────────────────────────────────────────────────
          // 3️⃣ NO DATA STATE
          // ─────────────────────────────────────────────────────────────────
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _NoUserDocumentWidget(
              userId: user.uid,
              email: user.email ?? 'Unknown',
              onCreateProfile: () => _createUserProfile(user),
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // 4️⃣ SUCCESS: Extract role and route
          // ─────────────────────────────────────────────────────────────────
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final role = (data?['role'] ?? 'aspirant').toString().toLowerCase().trim();
          
          // Update cache
          _updateCache(role);
          
          // Reset retry count on success
          if (_retryCount > 0) {
            _retryCount = 0;
          }
          
          return _routeToRoleBasedDashboard(role);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🚨 INTELLIGENT ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _handleStreamError(Object error, String userId) {
    _logError('Firestore stream error', error);

    // Classify error type
    final errorType = _classifyError(error);

    switch (errorType) {
      case ErrorType.timeout:
      case ErrorType.networkFailure:
        // Max retries reached: Show Retry Dialog with Offline Option
        return _ErrorStateWidget(
          title: 'Connection Failed',
          message: 'We couldn\'t connect to the server after multiple attempts.',
          icon: Icons.cloud_off,
          onRetry: _manualRetry,
          onOfflineMode: _cachedRole != null ? _enterOfflineMode : null,
          onLogout: _handleLogout,
        );

      case ErrorType.permissionDenied:
        // Firebase security rules issue
        return _ErrorStateWidget(
          title: 'Access Denied',
          message: 'Your account doesn\'t have permission to access this data.',
          icon: Icons.lock,
          onContactSupport: () {
            _logInfo('User requested support for permission error');
            // TODO: Open support form
          },
          onLogout: _handleLogout,
        );

      case ErrorType.documentNotFound:
        // User document missing
        return _NoUserDocumentWidget(
          userId: userId,
          email: FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          onCreateProfile: () => _createUserProfile(FirebaseAuth.instance.currentUser!),
        );

      case ErrorType.unknown:
        // Generic error
        return _ErrorStateWidget(
          title: 'Something went wrong',
          message: kDebugMode ? error.toString() : 'An unexpected error occurred.',
          icon: Icons.error_outline,
          onRetry: _manualRetry,
          onLogout: _handleLogout,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔍 ERROR CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════

  ErrorType _classifyError(Object error) {
    final errorString = error.toString().toLowerCase();

    if (error is TimeoutException || errorString.contains('timeout')) {
      return ErrorType.timeout;
    }
    if (errorString.contains('permission-denied') || 
        errorString.contains('security')) {
      return ErrorType.permissionDenied;
    }
    if (errorString.contains('not-found') || 
        errorString.contains('no document')) {
      return ErrorType.documentNotFound;
    }
    if (errorString.contains('network') || 
        errorString.contains('unavailable')) {
      return ErrorType.networkFailure;
    }

    return ErrorType.unknown;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🔀 ROLE-BASED ROUTING (Clean Architecture)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _routeToRoleBasedDashboard(String role) {
    switch (role) {
      case 'student':
        return const HomeScreen();

      case 'driver':
        return const DriverDashboard();

      case 'faculty':
      case 'teacher':
      case 'professor':
      case 'admin':
      case 'administrator':
      case 'superadmin':
        return const AdminDashboard();

      default:
        if (role != 'aspirant') {
          _logError('Unknown role', 'Role: $role, defaulting to aspirant');
        }
        return const AspirantDashboard();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 🛠️ AUTO-CREATE USER PROFILE
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _createUserProfile(User user) async {
    try {
      _logInfo('Creating user profile for ${user.uid}');
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'New User',
        'role': 'aspirant',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _logInfo('User profile created successfully');
      
      // Update cache
      await _updateCache('aspirant');
      
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      _logError('Failed to create user profile', e, stackTrace);
      _showErrorSnackbar(context, 'Failed to create profile. Please try again.');
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

  // ✅ FIXED: Proper method signature with optional StackTrace parameter
  void _logError(String title, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log('❌ $title: $error', name: 'ROLE_DISPATCHER_ERROR', stackTrace: stackTrace);
    } else if (EnvConfig.enableCrashlytics) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: title);
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFCF6679),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 UI COMPONENTS (MUST BE TOP-LEVEL - NOT INSIDE OTHER CLASSES)
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
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final VoidCallback? onOfflineMode;
  final VoidCallback? onContactSupport;
  final VoidCallback? onLogout;

  const _ErrorStateWidget({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    this.onOfflineMode,
    this.onContactSupport,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFCF6679).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: const Color(0xFFCF6679)),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            
            if (onOfflineMode != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOfflineMode,
                icon: const Icon(Icons.offline_bolt),
                label: const Text('Continue Offline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8AB4F8),
                  side: const BorderSide(color: Color(0xFF8AB4F8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
            
            if (onContactSupport != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onContactSupport,
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact Support'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8AB4F8),
                ),
              ),
            ],

            if (onLogout != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                ),
              ),
            ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFAB00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off,
                size: 64,
                color: Color(0xFFFFAB00),
              ),
            ),
            const SizedBox(height: 32),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineWrapper extends StatelessWidget {
  final VoidCallback onRetry;
  final Widget child;

  const _OfflineWrapper({
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: const Color(0xFFFFAB00),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Offline Mode - Using cached data',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'RETRY',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}