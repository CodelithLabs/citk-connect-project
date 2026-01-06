import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📦 IMPORT ALL SCREENS
// ═══════════════════════════════════════════════════════════════════════════
import '../../splash/splash_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/views/staff_login_screen.dart';
import '../../onboarding/views/onboarding_screen.dart';
import 'role_dispatcher.dart';
import '../../auth/providers/auth_provider.dart';

// Import from main.dart
import 'package:citk_connect/main.dart' show onboardingStateProvider;

// TODO: Import future screens
// import '../../settings/views/settings_screen.dart';
// import '../../profile/views/profile_screen.dart';
// import '../../notifications/views/notifications_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🧭 ROUTER PROVIDER (Main Entry Point)
// ═══════════════════════════════════════════════════════════════════════════

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch authentication state changes
  final authStream = ref.watch(authStateChangesProvider.stream);

  // Watch onboarding completion state
  final seenOnboarding = ref.watch(onboardingStateProvider);

  // TODO: Watch feature flags when implemented
  // final featureFlags = ref.watch(featureFlagsProvider);

  return GoRouter(
    // ─────────────────────────────────────────────────────────────────────
    // 🚀 INITIAL LOCATION
    // ─────────────────────────────────────────────────────────────────────
    initialLocation: '/splash', // Start with splash for smooth UX

    // ─────────────────────────────────────────────────────────────────────
    // 🔄 REFRESH ON AUTH CHANGES
    // ─────────────────────────────────────────────────────────────────────
    refreshListenable: GoRouterRefreshStream(authStream),

    // ─────────────────────────────────────────────────────────────────────
    // 🛡️ ERROR HANDLING
    // ─────────────────────────────────────────────────────────────────────
    errorBuilder: (context, state) {
      _logError('Router Error', state.error ?? 'Unknown routing error');
      return _ErrorScreen(
        error: state.error?.toString() ?? 'Page not found',
        path: state.uri.path,
      );
    },

    // ─────────────────────────────────────────────────────────────────────
    // 🔀 GLOBAL REDIRECT LOGIC (Authentication & Onboarding Guard)
    // ─────────────────────────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      return _handleRedirect(
        context: context,
        state: state,
        seenOnboarding: seenOnboarding,
        currentUser: currentUser,
      );
    },

    // ─────────────────────────────────────────────────────────────────────
    // 🗺️ ROUTE DEFINITIONS
    // ─────────────────────────────────────────────────────────────────────
    routes: [
      // ───────────────────────────────────────────────────────────────────
      // 🌊 SPLASH SCREEN (Entry point)
      // ───────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ───────────────────────────────────────────────────────────────────
      // 📖 ONBOARDING SCREEN (First-time users)
      // ───────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) {
          return const OnboardingScreen();
        },
      ),

      // ───────────────────────────────────────────────────────────────────
      // 🔐 AUTHENTICATION ROUTES
      // ───────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/staff-login',
        name: 'staff-login',
        builder: (context, state) => const StaffLoginScreen(),
      ),

      // ───────────────────────────────────────────────────────────────────
      // 🏠 MAIN APP (Role-based dispatcher)
      // ───────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const RoleDispatcher(),
        // TODO: Add nested routes for authenticated screens
        // routes: [
        //   GoRoute(
        //     path: 'profile',
        //     name: 'profile',
        //     builder: (context, state) => const ProfileScreen(),
        //   ),
        //   GoRoute(
        //     path: 'settings',
        //     name: 'settings',
        //     builder: (context, state) => const SettingsScreen(),
        //   ),
        // ],
      ),

      // TODO: Add deep linking routes
      // GoRoute(
      //   path: '/event/:eventId',
      //   name: 'event-detail',
      //   builder: (context, state) {
      //     final eventId = state.pathParameters['eventId']!;
      //     return EventDetailScreen(eventId: eventId);
      //   },
      // ),

      // TODO: Add admin routes with role guard
      // GoRoute(
      //   path: '/admin',
      //   redirect: (context, state) {
      //     // Check if user has admin role
      //     return null; // or redirect to unauthorized
      //   },
      //   routes: [...],
      // ),
    ],
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// 🔀 REDIRECT LOGIC (Extracted for maintainability)
// ═══════════════════════════════════════════════════════════════════════════

String? _handleRedirect({
  required BuildContext context,
  required GoRouterState state,
  required bool seenOnboarding,
  required User? currentUser,
}) {
  final user = currentUser;
  final path = state.uri.path;

  _logInfo(
      'Redirect check: path=$path, user=${user?.uid}, onboarding=$seenOnboarding');

  // ───────────────────────────────────────────────────────────────────────
  // PRIORITY 1: Splash Screen (Always allow, no redirect)
  // ───────────────────────────────────────────────────────────────────────
  if (path == '/splash') {
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────
  // PRIORITY 2: Onboarding Check (Must see onboarding before anything else)
  // ───────────────────────────────────────────────────────────────────────
  if (!seenOnboarding) {
    // User hasn't completed onboarding
    if (path != '/onboarding') {
      _logInfo('Redirecting to onboarding (not seen yet)');
      return '/onboarding';
    }
    // User is already on onboarding screen
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────
  // PRIORITY 3: Authentication Check
  // ───────────────────────────────────────────────────────────────────────

  // 🔓 USER IS NOT LOGGED IN
  if (user == null) {
    // Allow access to login screens and onboarding
    if (_isPublicRoute(path)) {
      return null;
    }
    // Redirect unauthenticated users to login
    _logInfo('Redirecting to login (not authenticated)');
    return '/login';
  }

  // 🔐 USER IS LOGGED IN
  if (user != null) {
    // Prevent authenticated users from accessing login screens
    if (_isAuthRoute(path)) {
      _logInfo('Redirecting to home (already authenticated)');
      return '/'; // Go to RoleDispatcher
    }

    // If trying to access onboarding while logged in, redirect to home
    if (path == '/onboarding') {
      _logInfo('Redirecting to home (onboarding not needed)');
      return '/';
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // PRIORITY 4: Role-Based Access Control (TODO)
  // ───────────────────────────────────────────────────────────────────────
  // TODO: Check user role from Firestore and restrict routes
  // Example:
  // if (path.startsWith('/admin') && userRole != 'admin') {
  //   return '/unauthorized';
  // }

  // ───────────────────────────────────────────────────────────────────────
  // PRIORITY 5: Feature Flags (TODO)
  // ───────────────────────────────────────────────────────────────────────
  // TODO: Check if route requires a feature flag
  // if (path == '/beta-feature' && !featureFlags['enable_beta']) {
  //   return '/';
  // }

  // No redirect needed
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// 🛠️ HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Routes that don't require authentication
bool _isPublicRoute(String path) {
  return path == '/login' ||
      path == '/staff-login' ||
      path == '/onboarding' ||
      path == '/splash';
}

/// Routes that are only for authentication
bool _isAuthRoute(String path) {
  return path == '/login' || path == '/staff-login';
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔄 ROUTER REFRESH STREAM (Rebuild router on auth changes)
// ═══════════════════════════════════════════════════════════════════════════

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (event) {
        _logInfo('Auth state changed, refreshing router');
        notifyListeners();
      },
      onError: (error) {
        _logError('Auth stream error', error);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🐛 LOGGING UTILITIES
// ═══════════════════════════════════════════════════════════════════════════

void _logInfo(String message) {
  if (kDebugMode) {
    developer.log('🧭 $message', name: 'ROUTER');
  }
}

void _logError(String title, Object error) {
  if (kDebugMode) {
    developer.log('❌ $title: $error', name: 'ROUTER_ERROR');
  }
  // TODO: Send to crash reporting in production
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 ERROR SCREEN (When routing fails)
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorScreen extends StatelessWidget {
  final String error;
  final String path;

  const _ErrorScreen({required this.error, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFCF6679),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                '404',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cannot find route: $path',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

