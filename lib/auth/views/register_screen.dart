import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback onSignInClicked;
  const RegisterScreen({super.key, required this.onSignInClicked});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Default values
  String _selectedDept = 'CSE';
  String _selectedSem = '1st';
  
  bool _isLoading = false;

  final List<String> _departments = ['CSE', 'ECE', 'IE', 'FET', 'Civil', 'Animation'];
  final List<String> _semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider.notifier).signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        department: _selectedDept,
        semester: _selectedSem,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration Failed: ${e.toString()}"),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignUp() async {
     try {
       await ref.read(authServiceProvider.notifier).signInWithGoogle();
     } catch (e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign In Error: $e")));
       }
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
                Icon(Icons.person_add_outlined, size: 60, color: theme.colorScheme.primary)
                    .animate().scale(),
                const SizedBox(height: 16),
                
                Text('Join CITK Connect', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                    .animate().fadeIn(),
                
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => !v!.contains('@') ? "Invalid email" : null,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // FIXED: Changed 'value' to 'initialValue' to fix deprecation warning
                        initialValue: _selectedDept,
                        decoration: const InputDecoration(labelText: 'Dept', prefixIcon: Icon(Icons.school_outlined)),
                        items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _selectedDept = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // FIXED: Changed 'value' to 'initialValue' to fix deprecation warning
                        initialValue: _selectedSem,
                        decoration: const InputDecoration(labelText: 'Sem', prefixIcon: Icon(Icons.calendar_today_outlined)),
                        items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedSem = v!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                ),
                
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account'),
                ),
                
                const SizedBox(height: 16),
                
                 OutlinedButton.icon(
                  onPressed: _googleSignUp,
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
                  label: const Text("Sign up with Google"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade700),
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: widget.onSignInClicked,
                  child: RichText(
                    text: TextSpan(
                      text: "Already a member? ",
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(text: "Login", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
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