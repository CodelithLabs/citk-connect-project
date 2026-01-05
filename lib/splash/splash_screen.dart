import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 10 Facts about CITK (Mix of history and student life)
  List<String> _facts = [
    "Did you know? CITK was established on December 19, 2006.",
    "CITK is centrally funded by the Ministry of HRD, Govt. of India.",
    "The campus spans over huge acres of lush greenery in Kokrajhar.",
    "Our goal: Becoming a hub for technical education in the Bodoland Territorial Region.",
    "CITK Connect: Built by students, for students.",
    "Powered by Google Firebase & Flutter technology.",
    "Connecting departments: From CSE to Food Engineering.",
    "Animation, Design, and Code: All in one app.",
    "Your attendance, grades, and events—simplified.",
    "Getting things ready for you...",
  ];

  int _currentFactIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRemoteFacts(); // ☁️ Fetch dynamic facts
    _facts.shuffle(); // 🔀 Randomize facts so it's different every time

    // Rotate facts every 2.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      setState(() {
        _currentFactIndex = (_currentFactIndex + 1) % _facts.length;
      });
    });

    // Navigate to Auth/Home after 8 seconds (or however long your loading logic takes)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) context.go('/onboarding'); // Go to onboarding first!
    });
  }

  // ☁️ REMOTE CONFIG: Fetch facts from Firestore
  Future<void> _fetchRemoteFacts() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'splash_facts_cache';

    // 1. Load Cache First (Instant UI)
    final cachedFacts = prefs.getStringList(cacheKey);
    if (cachedFacts != null && cachedFacts.isNotEmpty) {
      if (mounted) {
        setState(() {
          _facts = cachedFacts;
          _facts.shuffle();
        });
      }
    }

    // 2. Fetch Fresh Data
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('splash')
          .get();
      if (doc.exists && doc.data()?['facts'] != null) {
        final newFacts = List<String>.from(doc.data()!['facts']);

        // Save to Cache
        await prefs.setStringList(cacheKey, newFacts);

        if (mounted) {
          setState(() {
            _facts = newFacts;
            _facts.shuffle();
            _currentFactIndex =
                0; // 🛡️ Safety: Reset index to prevent RangeError
          });
        }
      }
    } catch (_) {} // Silent fail: keep default facts
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient (Subtle professional look)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15), // FIXED
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Logo
              const Icon(Icons.hub, size: 80, color: Colors.white)
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                      duration: 1000.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1))
                  .then()
                  .shimmer(duration: 2000.ms, color: const Color(0xFF4285F4)),

              const SizedBox(height: 20),

              Text(
                "CITK CONNECT",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
              ).animate().fadeIn(duration: 800.ms).moveY(begin: 20, end: 0),

              const Spacer(),

              // Rotating Facts with AnimatedSwitcher
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _facts[_currentFactIndex],
                      key: ValueKey<int>(_currentFactIndex), // ✅ Has key
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Google Colored Loader
              const CircularProgressIndicator(
                color: Color(0xFF4285F4), // Google Blue
              ),

              const SizedBox(height: 50),
            ],
          ),
        ],
      ),
    );
  }
}
