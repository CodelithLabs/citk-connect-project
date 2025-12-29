import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports
import 'package:citk_connect/splash/splash_screen.dart';
import 'package:citk_connect/onboarding/views/onboarding_screen.dart';
import 'package:citk_connect/auth/views/auth_gate.dart';
import 'package:citk_connect/home/views/home_screen.dart';
import 'package:citk_connect/ai/views/chat_screen.dart';
import 'package:citk_connect/emergency/views/emergency_screen.dart'; // Ensure folder is 'views'

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthGate()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/ai', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/emergency', builder: (context, state) => const EmergencyScreen()),
    ],
  );
}