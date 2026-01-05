import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HostelSelectorPopup extends StatefulWidget {
  const HostelSelectorPopup({super.key});

  @override
  State<HostelSelectorPopup> createState() => _HostelSelectorPopupState();
}

class _HostelSelectorPopupState extends State<HostelSelectorPopup> {
  bool _isLoading = false;

  Future<void> _updateStatus(String status, String? hostelName) async {
    // 🛡️ FIX: Capture navigator before async gap to prevent context issues
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isHosteller': status == 'Hosteller',
        'hostelName': hostelName ?? 'Day Scholar',
        'address': status == 'Hosteller' ? 'CITK Campus' : 'Commuter',
      }, SetOptions(merge: true));
    }
    if (mounted) navigator.pop(); // Close Popup safely
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF181B21).withValues(alpha: 0.85),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.night_shelter_rounded,
                        color: Color(0xFF6C63FF), size: 48)
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text(
                  "Where do you crash?",
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Help us customize your bus schedule & notifications.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 30),

                // Option 1: Hostel
                _optionBtn("I live in a Hostel", const Color(0xFF6C63FF), () {
                  _showHostelList(); // Ask which hostel
                }),

                const SizedBox(height: 16),

                // Option 2: Day Scholar
                _optionBtn("I'm a Day Scholar", Colors.cyanAccent, () {
                  _updateStatus('Day Scholar', null);
                }),
              ].animate(interval: 100.ms).fade().slideY(begin: 0.2, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  void _showHostelList() {
    // Simple list for now
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF181B21),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            Text("Select Your Hostel",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _hostelTile("RNB Hostel (Boys)"),
            _hostelTile("SCVR Hostel (Boys)"),
            _hostelTile("Jwngma Hostel (Girls)"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _hostelTile(String name) {
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white)),
      leading: const Icon(Icons.bed, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // Close sheet
        _updateStatus('Hosteller', name);
      },
    );
  }

  Widget _optionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
