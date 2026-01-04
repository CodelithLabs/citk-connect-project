import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedTab = 0; // 0 = Student, 1 = Aspirant
  bool _isLoading = false;

  // 🛠️ MAIN LOGIN LOGIC
  Future<void> _handleSmartLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. Trigger Google Sign-In via Riverpod Service
      await ref.read(authServiceProvider.notifier).signInWithGoogle();

      // 2. Fetch current user to validate rules
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Login cancelled");

      final email = user.email ?? "";

      // ============================
      // 🔐 STUDENT TAB SECURITY RULES
      // ============================
      if (_selectedTab == 0) {
        // Rule: Must end in @cit.ac.in AND have numbers (e.g. d25...)
        final bool isStudentEmail =
            email.endsWith("@cit.ac.in") && RegExp(r'\d').hasMatch(email.split('@')[0]);

        // Exception: Explicit Developer Whitelist
        final bool isDeveloper = email == "codelithlabs@gmail.com" ||
            email == "work.prasanta.ray@gmail.com";

        if (!isStudentEmail && !isDeveloper) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showError("Access Denied: Use your official college email (e.g., d25...@cit.ac.in).");
          }
          return;
        }
      }

      // ============================
      // 🌱 ASPIRANT TAB RULES
      // ============================
      if (_selectedTab == 1) {
        // Rule: Existing students shouldn't use Aspirant tab
        if (email.endsWith("@cit.ac.in")) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showError("You already have a college ID. Use the Student tab.");
          }
          return;
        }

        // Redirect Aspirants manually (Student flow is handled by auth_state_switch in main.dart)
        if (mounted) context.go('/aspirant-dashboard');
      }

    } catch (e) {
      if (mounted) {
        _showError("Login Failed: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🛠️ MISSING FUNCTION FIXED HERE
  void _handleDevBypass() {
    // Shortcut to Admin/Staff login for testing
    context.push('/staff-login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Developer Shortcut: Opening Staff Portal 🛠️"),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1115);
    const surface = Color(0xFF181B21);
    const primary = Colors.white;

    return Scaffold(
      backgroundColor: bgDark,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Blob 1
          Positioned(
            top: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Background Blob 2
          Positioned(
            bottom: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // HEADER ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _IdentityMorphWidget(),
                      GestureDetector(
                        onTap: _handleDevBypass, // ✅ Error Fixed
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.bug_report, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                "DEBUG",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // MAIN TITLE & SUBTITLE
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTab == 0
                              ? "Student\nPortal."
                              : "Future\nStudent.",
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        )
                            .animate(key: ValueKey('title-$_selectedTab'))
                            .fadeIn()
                            .moveY(begin: 20.0, end: 0.0),

                        const SizedBox(height: 16),

                        Text(
                          _selectedTab == 0
                              ? "Your digital campus gateway.\nBus tracking, Routine & AI Assistant."
                              : "Dreaming of CITK?\nExplore admission details & campus life.",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[400],
                            height: 1.5,
                          ),
                        )
                            .animate(key: ValueKey('subtitle-$_selectedTab'))
                            .fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),

                  // LOGIN CONTROLS
                  Column(
                    children: [
                      // Toggle Switch
                      Container(
                        padding: const EdgeInsets.all(4),
                        height: 55,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            _buildTab("Student", 0),
                            _buildTab("Aspirant", 1),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSmartLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: bgDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : Text(
                                  _selectedTab == 0
                                      ? "Continue with College Email"
                                      : "Explore with Google",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.0, 1.0),
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 24),

                      // Staff Login Link
                      GestureDetector(
                        onTap: () => context.push('/staff-login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 10),
                              Text(
                                "Faculty & Driver Access",
                                style: GoogleFonts.inter(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A2D35) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

// 🪄 FANCY ANIMATION WIDGET
class _IdentityMorphWidget extends StatefulWidget {
  const _IdentityMorphWidget();

  @override
  State<_IdentityMorphWidget> createState() => _IdentityMorphWidgetState();
}

class _IdentityMorphWidgetState extends State<_IdentityMorphWidget> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _index = (_index + 1) % 2);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _index == 0
          ? _row("CITK CONNECT", Icons.hub, const ValueKey('citk'))
          : _row("CODELITH LABS", Icons.code, const ValueKey('codelith')),
    );
  }

  Widget _row(String text, IconData icon, Key key) {
    return Row(
      key: key,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}