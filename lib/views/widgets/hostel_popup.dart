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
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isHosteller': status == 'Hosteller',
        'hostelName': hostelName ?? 'Day Scholar',
        'address': status == 'Hosteller' ? 'CITK Campus' : 'Commuter',
      }, SetOptions(merge: true));
    }
    if (mounted) Navigator.pop(context); // Close Popup
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181B21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.night_shelter_rounded, color: Colors.purpleAccent, size: 40)
                .animate().scale(),
            const SizedBox(height: 16),
            Text(
              "Where do you crash?",
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Help us customize your bus schedule & notifications.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Option 1: Hostel
            _optionBtn("I live in a Hostel", Colors.purpleAccent, () {
              _showHostelList(); // Ask which hostel
            }),
            
            const SizedBox(height: 12),
            
            // Option 2: Day Scholar
            _optionBtn("I'm a Day Scholar", Colors.blueAccent, () {
              _updateStatus('Day Scholar', null);
            }),
          ],
        ),
      ),
    );
  }

  void _showHostelList() {
    // Simple list for now
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181B21),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Your Hostel", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _hostelTile("RNB Hostel (Boys)"),
            _hostelTile("SCVR Hostel (Boys)"),
            _hostelTile("Jwngma Hostel (Girls)"),
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
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}