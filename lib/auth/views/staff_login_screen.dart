import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  int _selectedTab = 0; // 0 = Faculty, 1 = Driver
  bool _isLoading = false;

  final _vehicleIdController = TextEditingController();
  final _pinController = TextEditingController();

  // 👑 SPECIAL DEVELOPER / MAINTAINER ACCOUNTS
  bool _isSpecialDeveloper(String email) {
    const allowed = [
      'codelithlabs@gmail.com',
      'maintainer@cit.ac.in',
    ];
    return allowed.contains(email);
  }

  bool _looksLikeStudent(String username) {
    return RegExp(r'^(d|u|p|ph)[0-9]{2}').hasMatch(username);
  }

  // ============================================================
  // 🎓 FACULTY LOGIN (GOOGLE)
  // ============================================================
  Future<void> _handleFacultyLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider.notifier).signInWithGoogle();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Login cancelled");

      final email = user.email ?? "";

      // 🔓 Special developer bypass
      if (_isSpecialDeveloper(email)) {
        _toast("Developer mode activated 🛠️");
        return;
      }

      // 🛡️ Must be official faculty domain
      if (!email.endsWith('@cit.ac.in')) {
        await FirebaseAuth.instance.signOut();
        _showError("Restricted: Official faculty account required.");
        return;
      }

      // 🛡️ Block student-style emails
      final prefix = email.split('@').first;
      if (_looksLikeStudent(prefix)) {
        await FirebaseAuth.instance.signOut();
        _showError("Student accounts must use the Student Portal.");
        return;
      }

      _toast("Welcome, Professor.");
      // context.go('/admin-dashboard'); // add later
    } catch (e) {
      _showError("Faculty login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🚌 DRIVER LOGIN (REAL FIREBASE)
  // ============================================================
  Future<void> _handleDriverLogin() async {
    setState(() => _isLoading = true);

    final vehicleId = _vehicleIdController.text.trim();
    final pin = _pinController.text.trim();

    if (vehicleId.isEmpty || pin.isEmpty) {
      _showError("Enter Vehicle ID and PIN.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 🔒 SECURE PIN VERIFICATION (Fleet Registry)
      final doc = await FirebaseFirestore.instance
          .collection('fleet')
          .doc(vehicleId)
          .get();

      if (!doc.exists || doc.data()?['pin'] != pin) {
        // Generic error message for security
        _showError("Access Denied: Invalid Vehicle ID or PIN.");
        setState(() => _isLoading = false);
        return;
      }

      await ref.read(authServiceProvider.notifier).signInAsDriver(vehicleId);
      _toast("Vehicle system online.");
      // context.go('/driver-dashboard'); // add later
    } catch (e) {
      _showError("Driver login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
    const accent = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.grey, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _badge(accent),
                    const SizedBox(height: 20),
                    Text(
                      "Staff & Faculty\nAccess Portal.",
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ).animate().fadeIn().moveY(begin: 20, end: 0),
                    const SizedBox(height: 40),
                    _tabs(surface, accent),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedTab == 0
                          ? _facultyPanel()
                          : _driverPanel(accent),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        "Unauthorized access attempts are logged.",
                        style: GoogleFonts.robotoMono(
                          color: Colors.grey[700],
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        "RESTRICTED AREA",
        style: GoogleFonts.robotoMono(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tabs(Color surface, Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      height: 55,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTab("Faculty", 0, accent),
          _buildTab("Transport", 1, accent),
        ],
      ),
    );
  }

  Widget _facultyPanel() {
    return Column(
      key: const ValueKey('faculty'),
      children: [
        const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleFacultyLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Text("Authenticate with Google"),
          ),
        ),
      ],
    );
  }

  Widget _driverPanel(Color accent) {
    return Column(
      key: const ValueKey('driver'),
      children: [
        _field("Vehicle ID", Icons.directions_bus, _vehicleIdController),
        const SizedBox(height: 16),
        _field("Access PIN", Icons.lock_outline, _pinController, obscure: true),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleDriverLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black)
                : const Text("Initialize Vehicle System"),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, Color accent) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A2D35) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? accent : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
