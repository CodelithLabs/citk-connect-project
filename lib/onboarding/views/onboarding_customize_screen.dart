import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingCustomizeScreen extends StatefulWidget {
  const OnboardingCustomizeScreen({super.key});

  @override
  State<OnboardingCustomizeScreen> createState() =>
      _OnboardingCustomizeScreenState();
}

class _OnboardingCustomizeScreenState extends State<OnboardingCustomizeScreen> {
  final List<String> _selectedInterests = [];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 50),
          Image.asset(
            'assets/images/logo.png',
            height: 100,
            width: 100,
          ),
          const Column(
            children: [
              Text(
                'TAILOR TO YOUR EXPERIENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              InterestButton(
                text: '3D map',
                isSelected: _selectedInterests.contains('3D map'),
                onPressed: () => _toggleInterest('3D map'),
              ),
              InterestButton(
                text: 'Campus news',
                isSelected: _selectedInterests.contains('Campus news'),
                onPressed: () => _toggleInterest('Campus news'),
              ),
              InterestButton(
                text: 'Seniors Help',
                isSelected: _selectedInterests.contains('Seniors Help'),
                onPressed: () => _toggleInterest('Seniors Help'),
              ),
              InterestButton(
                text: 'AI',
                isSelected: _selectedInterests.contains('AI'),
                onPressed: () => _toggleInterest('AI'),
              ),
              InterestButton(
                text: 'PYQ',
                isSelected: _selectedInterests.contains('PYQ'),
                onPressed: () => _toggleInterest('PYQ'),
              ),
              InterestButton(
                text: 'Emergency help',
                isSelected: _selectedInterests.contains('Emergency help'),
                onPressed: () => _toggleInterest('Emergency help'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                context.go('/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InterestButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const InterestButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
