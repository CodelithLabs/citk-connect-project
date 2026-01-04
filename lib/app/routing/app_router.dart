import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import all your views...
import '../../splash/splash_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/views/staff_login_screen.dart';
import 'role_dispatcher.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    initialLocation: '/', // Everyone starts here
    refreshListenable: GoRouterRefreshStream(authStream),

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final path = state.uri.path;

      // 1. Splash is always allowed
      if (path == '/splash') return null;

      // 2. If user is NOT logged in
      if (user == null) {
        // Allow them to visit Login or Staff Login
        if (path == '/login' || path == '/staff-login') return null;
        // Otherwise, force them to Splash or Login
        return '/login';
      }

      // 3. If user IS logged in
      // If they are on Login pages, send them to the Dispatcher
      if (path == '/login' || path == '/staff-login') {
        return '/';
      }

      return null;
    },

    routes: [
      // 🌟 THE BRAIN: Decides where to go based on Firestore Role
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleDispatcher(),
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
      
      // 🌊 Splash (Optional)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});

// (Keep your GoRouterRefreshStream class here, it was correct)
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}