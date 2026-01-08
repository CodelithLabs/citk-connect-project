import 'package:citk_connect/auth/services/auth_service.dart';
//import 'package:citk_connect/common/widgets/floating_role_toggle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _OnboardingView(),
    );
  }
}

class _OnboardingView extends HookConsumerWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final isStudent = useState(true);
    final selectedDept = useState<String?>(null);
    final departments = [
      'CSE',
      'ECE',
      'IE',
      'FET',
      'CE',
      'MCD',
      'Basic Science'
    ];

    final pages = [
      _OnboardingPage(
        title: isStudent.value ? 'Welcome, Student' : 'Welcome, Aspirant',
        description: isStudent.value
            ? 'Manage your classes, hostel, and bus tracking in one place.'
            : 'Explore the CITK campus, courses, and admission details.',
      ),
      _OnboardingPage(
        title: isStudent.value ? 'Campus Life' : 'Future Ready',
        description: isStudent.value
            ? 'Track buses live and chat with the AI assistant for help.'
            : 'Get insights into departments and campus facilities.',
      ),
      if (!isStudent.value)
        _OnboardingPage(
          title: 'Campus Map',
          description: 'Navigate the 300-acre campus with our interactive map.',
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF181B21),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                // Technical Grid Pattern
                Positioned.fill(
                  child: GridPaper(
                    color: Colors.white.withValues(alpha: 0.05),
                    interval: 40,
                    divisions: 1,
                    subdivisions: 1,
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_outlined,
                        size: 48, color: Color(0xFF6C63FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      _OnboardingPage(
        title: 'Ready to Begin?',
        description: 'Sign in to start exploring.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isStudent.value)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF181B21),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDept.value,
                    hint: Text(
                      'Select Department',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                    dropdownColor: const Color(0xFF181B21),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF6C63FF)),
                    items: departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(
                          dept,
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => selectedDept.value = val,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                if (!isStudent.value && selectedDept.value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a department',
                          style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                await ref.read(authServiceProvider.notifier).signInWithGoogle();

                if (!isStudent.value && selectedDept.value != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({'department': selectedDept.value},
                            SetOptions(merge: true));
                  }
                }
              },
              child: Text(isStudent.value ? 'Student Login' : 'Guest Login'),
            ),
          ],
        ),
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color:
          isStudent.value ? const Color(0xFF0F1115) : const Color(0xFF181B21),
      child: Stack(
        children: [
          PageView(
            controller: pageController,
            children: pages,
          ),
          // Floating Role Toggle
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Switch(
                value: isStudent.value,
                onChanged: (val) => isStudent.value = val,
                activeThumbColor: const Color(0xFF6C63FF),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (child != null) ...[
            const SizedBox(height: 40),
            child!,
          ],
        ],
      ),
    );
  }
}
