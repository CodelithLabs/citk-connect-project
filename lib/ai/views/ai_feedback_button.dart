import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/ai/services/gemini_service.dart';

class AiFeedbackButton extends ConsumerStatefulWidget {
  final String query;
  final String response;

  const AiFeedbackButton({
    super.key,
    required this.query,
    required this.response,
  });

  @override
  ConsumerState<AiFeedbackButton> createState() => _AiFeedbackButtonState();
}

class _AiFeedbackButtonState extends ConsumerState<AiFeedbackButton> {
  bool? _isHelpful;

  void _submit(bool value) {
    setState(() => _isHelpful = value);
    ref.read(geminiServiceProvider).submitFeedback(
          query: widget.query,
          response: widget.response,
          isHelpful: value,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? "Thanks! We'll keep it up. 🔥" : "Noted. We'll do better. 🫡",
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181B21),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHelpful != null) return const SizedBox.shrink(); // Hide after voting

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.thumb_up_alt_outlined,
              size: 16, color: Colors.grey),
          onPressed: () => _submit(true),
          tooltip: "Helpful",
        ),
        IconButton(
          icon: const Icon(Icons.thumb_down_alt_outlined,
              size: 16, color: Colors.grey),
          onPressed: () => _submit(false),
          tooltip: "Not Helpful",
        ),
      ],
    );
  }
}
