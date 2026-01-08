import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _displayText = 'CITK CONNECT';

  @override
  void initState() {
    super.initState();

    // 🔀 Morph Text Logic (1.5s delay)
    Future.delayed(1500.ms, () {
      if (mounted) {
        setState(() => _displayText = 'CODELITH LABS');
      }
    });

    // ⏱️ Navigate to Home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Deep Dark Background
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🏛️ CIT Logo Representation (Abstract & Clean)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: Color(0xFF6C63FF),
                  ),
                )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 600.ms)
                    .shimmer(
                        delay: 1000.ms,
                        duration: 1500.ms,
                        color: Colors.white.withValues(alpha: 0.5))
                    .then() // Chain animation
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        end: 1.05,
                        duration: 2000.ms,
                        curve: Curves.easeInOut), // Breathing effect

                const SizedBox(height: 40),

                // 📝 Title Animation
                SizedBox(
                  height: 40,
                  child: AnimatedSwitcher(
                    duration: 600.ms,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutBack)),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _displayText,
                      key: ValueKey(_displayText),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOut), // Initial Entrance

                const SizedBox(height: 12),

                // 🏷️ Subtitle
                Text(
                  'CAMPUS ECOSYSTEM',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                    color: Colors.grey,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
              ],
            ),
          ),
          // ⏩ Skip Button
          Positioned(
            bottom: 40,
            right: 24,
            child: TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SKIP',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ),
        ],
      ),
    );
  }
}
