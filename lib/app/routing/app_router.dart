import 'package:citk_connect/admin/views/post_update_screen.dart';
import 'package:citk_connect/ai/views/chat_screen.dart';
import 'package:citk_connect/app/view/scaffold_with_nav_bar.dart';
import 'package:citk_connect/home/home_page.dart';
import 'package:citk_connect/map/views/bus_tracker_screen.dart';
import 'package:citk_connect/onboarding/views/splash_screen.dart';
import 'package:citk_connect/profile/views/help_support_screen.dart';
import 'package:citk_connect/profile/views/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bus',
                name: 'bus',
                builder: (context, state) => const BusTrackerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'help',
                    name: 'help',
                    builder: (context, state) => const HelpSupportScreen(),
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
        builder: (context, state) => const PostUpdateScreen(),
        redirect: (context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return '/'; // Not logged in? Back to home.

          // 🛡️ Security Check: Verify Role in Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final role = doc.data()?['role'];
          // Only 'faculty' can pass. Everyone else gets kicked to Home.
          if (role != 'faculty') return '/';

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
