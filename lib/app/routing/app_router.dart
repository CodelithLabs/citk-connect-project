import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/home/home.dart';
import 'package:citk_connect/onboarding/views/onboarding_page.dart';
import 'package:citk_connect/profile/views/profile_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.asData?.value != null;

      if (!isAuth) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
}
