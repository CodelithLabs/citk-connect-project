import 'dart:async';
import 'package:citk_connect/admin/views/post_update_screen.dart';
import 'package:citk_connect/ai/views/chat_screen.dart';
import 'package:citk_connect/app/view/scaffold_with_nav_bar.dart';
import 'package:citk_connect/auth/providers/auth_provider.dart';
import 'package:citk_connect/auth/services/onboarding_service.dart';
import 'package:citk_connect/auth/views/login_screen.dart';
import 'package:citk_connect/map/views/bus_tracker_screen.dart';
import 'package:citk_connect/map/views/campus_map_screen.dart';
import 'package:citk_connect/map/views/ar_navigation_screen.dart';
import 'package:citk_connect/emergency/views/emergency_screen.dart';
import 'package:citk_connect/onboarding/views/onboarding_screen.dart';
import 'package:citk_connect/onboarding/views/splash_screen.dart';
import 'package:citk_connect/fees/views/fees_selection_screen.dart';
import 'package:citk_connect/common/views/app_web_view.dart';
import 'package:citk_connect/profile/views/help_support_screen.dart';
import 'package:citk_connect/profile/views/profile_screen.dart';
import 'package:citk_connect/profile/views/digital_locker_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'role_dispatcher.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final onboardingSeen = ref.watch(onboardingServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null; // Let splash finish its timer

      // 1. Onboarding Check
      if (!onboardingSeen) {
        if (state.matchedLocation == '/onboarding') return null;
        return '/onboarding';
      }

      // 2. Auth Check
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 3. If logged in and trying to access login/onboarding, go home
      if (isLoggingIn || state.matchedLocation == '/onboarding') {
        return '/';
      }

      return null; // Allow navigation
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          final targetTheme = state.uri.queryParameters['targetTheme'];
          return _buildPageWithTransition(
              context, state, SplashScreen(targetTheme: targetTheme));
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildSlideFadeTransition(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/emergency',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const EmergencyScreen()),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const CampusMapScreen()),
      ),
      GoRoute(
        path: '/ar',
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const ArNavigationScreen()),
      ),
      GoRoute(
        path: '/fees',
        pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const FeesSelectionScreen()),
      ),
      GoRoute(
        path: '/webview',
        pageBuilder: (context, state) {
          final url = state.uri.queryParameters['url']!;
          final title = state.uri.queryParameters['title'] ?? 'Browser';
          return _buildPageWithTransition(
              context, state, AppWebView(url: url, title: title));
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            _buildPageWithTransition(context, state,
                ScaffoldWithNavBar(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                // 🛡️ RoleDispatcher decides which Dashboard to show
                pageBuilder: (context, state) => _buildPageWithTransition(
                    context, state, const RoleDispatcher()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bus',
                name: 'bus',
                pageBuilder: (context, state) => _buildPageWithTransition(
                    context, state, const BusTrackerScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                pageBuilder: (context, state) => _buildPageWithTransition(
                    context, state, const ChatScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => _buildPageWithTransition(
                    context, state, const ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'help',
                    name: 'help',
                    pageBuilder: (context, state) => _buildPageWithTransition(
                        context, state, const HelpSupportScreen()),
                  ),
                  GoRoute(
                    path: 'locker',
                    name: 'locker',
                    pageBuilder: (context, state) => _buildPageWithTransition(
                        context, state, const DigitalLockerScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // 🔒 Admin Routes (Full Screen)
      GoRoute(
        path: '/admin/post-update',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const PostUpdateScreen()),
        redirect: (context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return '/'; // Not logged in? Back to home.

          // 🛡️ PBAC Security Check: Verify Permissions
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final List<dynamic> perms = doc.data()?['permissions'] ?? [];

          // Check for 'post_notice' permission OR Admin wildcard
          final hasAccess =
              perms.contains('post_notice') || perms.contains('*');

          if (!hasAccess) return '/';

          return null; // Access Granted
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('No route defined for ${state.uri}'),
      ),
    ),
  );
});

/// 🔄 Helper for Custom Transitions (Fade + Scale)
CustomTransitionPage _buildPageWithTransition(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
  );
}

/// 🔄 Helper for Slide + Fade Transition (Specific for Login)
CustomTransitionPage _buildSlideFadeTransition(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

/// 🔄 Utility class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
