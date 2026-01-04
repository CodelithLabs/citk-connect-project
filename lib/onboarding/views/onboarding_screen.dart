import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Welcome to CITK",
      "desc": "Track buses, view routines, and access everything you need — all in one app.",
      "icon": Icons.rocket_launch,
    },
    {
      "title": "Lost in Campus?",
      "desc": "Navigate CITK like a pro with interactive campus maps. Find hostels, labs, and canteens easily.",
      "icon": Icons.map_outlined,
    },
    {
      "title": "Need Help?",
      "desc": "Connect with seniors and get instant help from our AI Assistant anytime.",
      "icon": Icons.auto_awesome_outlined,
    },
    {
      "title": "Exam Ready",
      "desc": "Access routines, PYQs, and academic tools designed to help you succeed.",
      "icon": Icons.school_outlined,
    },
  ];

  void _finishOnboarding() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
     
    Text(
       "Welcome",
        style: theme.textTheme.headlineMedium,
    );
        
      final primaryColor = Colors.blueAccent;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text("SKIP", style: TextStyle(color: primaryColor)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'], size: 80, color: primaryColor),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 40),
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ).animate().fadeIn().moveY(begin: 20, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          page['desc'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400], height: 1.5),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryColor : Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: primaryColor,
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(duration: 300.ms, curve: Curves.easeInOut);
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Icon(_currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}