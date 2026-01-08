import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Toggle for Driver Mode
  bool _isDriverMode = false;
  
  // Driver Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For registration
  bool _isRegisteringDriver = false; // Toggle login/register for driver
  
  @override
  Widget build(BuildContext context) {
    // Watch Auth State for loading/error
    final authState = ref.watch(authServiceProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      // 🎨 RESIZE HANDLING: Prevents keyboard overlap errors
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // 1. AMBIENT BACKGROUND (Optimized for performance)
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurBlob(const Color(0xFF4285F4).withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(const Color(0xFFAB47BC).withValues(alpha: 0.1)),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim), child: child)),
                  // 🔀 LOGIC SWITCHER: Show Google Login OR Driver Form
                  child: _isDriverMode 
                    ? _buildDriverForm(isLoading) 
                    : _buildMainLogin(isLoading),
                ),
              ),
            ),
          ),
          
          // 3. LOADING OVERLAY (If needed globally)
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏢 VIEW 1: MAIN LOGIN (Students/Faculty/Aspirants)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMainLogin(bool isLoading) {
    return Column(
      key: const ValueKey('main'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LOGO ANIMATION
        const Icon(Icons.hub, size: 80, color: Colors.white)
            .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          "CITK CONNECT",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ).animate().fadeIn().moveY(begin: 10, end: 0),
        
        const SizedBox(height: 8),
        Text(
          "Central Institute of Technology, Kokrajhar",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 60),

        // 🔵 GOOGLE BUTTON
        _buildButton(
          label: "Continue with College Email",
          icon: FontAwesomeIcons.google,
          color: const Color(0xFF4285F4),
          onTap: () => ref.read(authServiceProvider.notifier).signInWithGoogle(),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 16),
        
        // ASPIRANT HINT
        Text(
          "Aspirant? Sign in with any Gmail account.",
          style: TextStyle(color: Colors.white24, fontSize: 12),
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 80),

        // 🚗 TOGGLE TO DRIVER MODE
        TextButton.icon(
          onPressed: () => setState(() => _isDriverMode = true),
          icon: const Icon(Icons.directions_bus, size: 16, color: Colors.white54),
          label: const Text("Driver / Staff Login", style: TextStyle(color: Colors.white54)),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚌 VIEW 2: DRIVER FORM (Email/Password)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDriverForm(bool isLoading) {
    return Column(
      key: const ValueKey('driver'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // BACK BUTTON
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _isDriverMode = false),
          ),
        ),
        const SizedBox(height: 20),
        
        Text(
          _isRegisteringDriver ? "Register Driver" : "Driver Login",
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          "Authorized transport staff only.",
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 40),

        // FORM FIELDS
        if (_isRegisteringDriver)
          _buildTextField("Full Name", Icons.person, _nameController),
        
        const SizedBox(height: 16),
        _buildTextField("Email Address", Icons.email, _emailController),
        const SizedBox(height: 16),
        _buildTextField("Password", Icons.lock, _passwordController, isPassword: true),

        const SizedBox(height: 32),

        // ACTION BUTTON
        _buildButton(
          label: _isRegisteringDriver ? "Create Account" : "Login",
          icon: _isRegisteringDriver ? Icons.person_add : Icons.login,
          color: const Color(0xFF43A047), // Green for Drivers
          onTap: _handleDriverSubmit,
        ),

        const SizedBox(height: 20),

        // TOGGLE LOGIN / REGISTER
        TextButton(
          onPressed: () => setState(() => _isRegisteringDriver = !_isRegisteringDriver),
          child: Text(
            _isRegisteringDriver ? "Already have an account? Login" : "Need an account? Register",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  // 🛠️ DRIVER SUBMIT LOGIC
  Future<void> _handleDriverSubmit() async {
    final auth = ref.read(authServiceProvider.notifier);
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    try {
      if (_isRegisteringDriver) {
        if (name.isEmpty) return;
        await auth.registerDriver(email: email, password: pass, name: name);
        if(mounted) setState(() => _isRegisteringDriver = false); // Go to login after reg
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created! Login now.")));
      } else {
        await auth.signInWithEmail(email: email, password: pass);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🎨 WIDGET BUILDERS
  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }
}