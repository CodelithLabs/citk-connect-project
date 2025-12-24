import 'package:citk_connect/app/auth/screens/login_screen.dart';
import 'package:citk_connect/app/auth/screens/signup_screen.dart';
import 'package:citk_connect/app/auth/services/auth_service.dart';
import 'package:citk_connect/app/shell/app_shell.dart';
import 'package:citk_connect/home/home.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.asData?.value != null;

      final isUnauthenticated = !isAuth &&
          (state.matchedLocation != '/login' &&
              state.matchedLocation != '/signup');

      if (isUnauthenticated) {
        return '/login';
      } else if (isAuth &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup')) {
        return '/';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignUpScreen(),
      ),
    ],
  );
}
