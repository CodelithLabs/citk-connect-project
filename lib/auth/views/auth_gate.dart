import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/auth/views/sign_in_screen.dart';
import 'package:citk_connect/auth/views/register_screen.dart';
import 'package:citk_connect/home/views/home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showRegister = false;

  void _toggle() => setState(() => _showRegister = !_showRegister);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const HomeScreen();
        
        // Toggle between screens
        return _showRegister 
            ? RegisterScreen(onSignInClicked: _toggle) 
            : SignInScreen(onRegisterClicked: _toggle);
      },
      // IMPORTANT: If loading, just show a loading indicator (not a new page)
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      
      // IMPORTANT: If error, we still show the Login screen so the user can retry.
      // We do NOT show a red error page here. The error is likely transient.
      error: (e, stack) => _showRegister 
          ? RegisterScreen(onSignInClicked: _toggle) 
          : SignInScreen(onRegisterClicked: _toggle),
    );
  }
}