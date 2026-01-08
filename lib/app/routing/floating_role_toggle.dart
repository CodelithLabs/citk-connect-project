import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingRoleToggle extends StatelessWidget {
  final bool isStudent;
  final ValueChanged<bool> onChanged;

  const FloatingRoleToggle({
    super.key,
    required this.isStudent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 204, // 100 * 2 + 4 padding
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          // Animated Pill Background
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: isStudent ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 100,
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Text Labels
          Row(
            children: [
              _buildOption(context, 'Student', true),
              _buildOption(context, 'Aspirant', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, bool targetState) {
    final isSelected = isStudent == targetState;
    return GestureDetector(
      onTap: () => onChanged(targetState),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 100,
        height: 44,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
