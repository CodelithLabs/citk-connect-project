import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/services/onboarding_service.dart';

// 1. Change to ConsumerStatefulWidget
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Lost in Campus?",
      "desc":
          "Navigate CITK like a pro with our 3D Campus Maps. Find hostels, labs, and canteens instantly.",
      "icon": Icons.map_outlined,
    },
    {
      "title": "Need Help?",
      "desc":
          "Don't struggle alone. Connect with seniors and get instant answers from our AI Assistant.",
      "icon": Icons.people_outline,
    },
    {
      "title": "Exam Ready",
      "desc":
          "Access Previous Year Questions (PYQ) and organize your study schedule in one place.",
      "icon": Icons.school_outlined,
    },
  ];

  // 2. Update this function
  void _finishOnboarding() {
    // Logic delegated to service. Router handles redirection automatically.
    ref.read(onboardingServiceProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. SKIP BUTTON
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text("SKIP",
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),

            // 2. PAGE VIEW (SWIPEABLE CONTENT)
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          page['title'],
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ).animate().fadeIn().moveY(begin: 20, end: 0),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page['desc'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. DOT INDICATORS & NEXT BUTTON
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Button
                  FloatingActionButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: theme.colorScheme.onPrimary,
                    ),
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
