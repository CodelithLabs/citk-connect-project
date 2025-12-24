import 'package:citk_connect/app/errors/errors.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(ref.watch(errorHandlerProvider));
}

@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}
