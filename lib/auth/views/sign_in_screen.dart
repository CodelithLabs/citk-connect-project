import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final VoidCallback onRegisterClicked;
  const SignInScreen({super.key, required this.onRegisterClicked});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider.notifier).signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";
      if (e.code == 'invalid-credential') message = "Incorrect email or password.";
      if (e.code == 'user-not-found') message = "No account found for this email.";
      if (e.code == 'wrong-password') message = "Wrong password.";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    try {
      await ref.read(authServiceProvider.notifier).signInWithGoogle();
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Error: Does your SHA-1 Key match Firebase? \n${e.toString()}"))
        );
      }
    }
  }
  
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email first.")));
      return;
    }
    try {
      await ref.read(authServiceProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent! Check your email.")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_person_rounded, size: 80, color: theme.colorScheme.primary).animate().scale(),
                const SizedBox(height: 24),
                
                Text('Welcome Back!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium).animate().fadeIn(),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
                  ),
                ),

                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Login'),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _googleLogin,
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
                  label: const Text("Continue with Google"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: Colors.grey.shade700), foregroundColor: Colors.white),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onRegisterClicked,
                  child: RichText(
                    text: TextSpan(
                      text: "New here? ",
                      style: const TextStyle(color: Colors.grey),
                      children: [TextSpan(text: "Create Account", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}