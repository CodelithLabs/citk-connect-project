import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../../splash/splash_screen.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/views/staff_login_screen.dart';
import '../../home/views/home_screen.dart';
import '../../home/views/aspirant_dashboard.dart';

// Dashboards
import '../../admin/views/admin_dashboard.dart';
import '../../driver/views/driver_dashboard.dart';

// Student Features
import '../../profile/views/profile_screen.dart';
import '../../map/views/campus_map_screen.dart';
import '../../map/views/bus_tracker_screen.dart';
import '../../ai/views/chat_screen.dart';
import '../../academics/views/routine_screen.dart';
import '../../home/views/events_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final path = state.uri.path;

      // 🌐 PUBLIC ROUTES
      final isPublic = path == '/' ||
          path == '/login' ||
          path == '/staff-login' ||
          path == '/onboarding' ||
          path == '/aspirant-dashboard';

      // 🔐 LOGGED IN USER
      if (user != null) {
        // Prevent going back to auth pages
        if (isPublic) {
          // Staff login → Admin dashboard
          if (path == '/staff-login') {
            return '/admin-dashboard';
          }

          // Default logged-in user → Student home
          return '/home';
        }

        return null;
      }

      // ❌ NOT LOGGED IN
      if (!isPublic) {
        return '/login';
      }

      return null;
    },

    routes: [
      // 🌟 Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // 🧭 Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 🔐 Authentication
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/staff-login',
        builder: (context, state) => const StaffLoginScreen(),
      ),

      // 🌱 Aspirant (Public)
      GoRoute(
        path: '/aspirant-dashboard',
        builder: (context, state) => const AspirantDashboard(),
      ),

      // 🎓 Student (Protected)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const CampusMapScreen(),
      ),
      GoRoute(
        path: '/bus',
        builder: (context, state) => const BusTrackerScreen(),
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/routine',
        builder: (context, state) => const RoutineScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),

      // 👑 Admin
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),

      // 🚌 Driver
      GoRoute(
        path: '/driver-dashboard',
        builder: (context, state) => const DriverDashboard(),
      ),
    ],
  );
});

/// 🔁 Refresh GoRouter on Firebase auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
