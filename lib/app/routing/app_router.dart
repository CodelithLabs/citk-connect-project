import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your pages
import 'package:citk_connect/auth/views/auth_screen.dart';
import 'package:citk_connect/home/views/home_screen.dart';
import 'package:citk_connect/onboarding/views/onboarding_customize_screen.dart';
import 'package:citk_connect/onboarding/views/onboarding_details_screen.dart';
import 'package:citk_connect/onboarding/views/onboarding_screen.dart';
import 'package:citk_connect/splash/splash_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final GoRouter router = GoRouter(
    initialLocation: '/', // Optional: explictly set initial route
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/details',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/customize',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingCustomizeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (BuildContext context, GoRouterState state) =>
            const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
    ],
  );

  return router; // <--- ADDED THIS (Vital!)
}