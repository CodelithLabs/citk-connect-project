import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Cannot dial on simulator");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency & Help",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade900),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade400, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Only use these contacts in case of genuine emergency.",
                    style: GoogleFonts.inter(color: Colors.red.shade100),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          _buildContactCard(
              context, "Medical", "108", Icons.local_hospital, Colors.green),
          _buildContactCard(context, "Chief Warden", "+919876543210",
              Icons.admin_panel_settings, Colors.blue),
          _buildContactCard(
              context, "Police", "100", Icons.local_police, Colors.red),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String phone,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(phone, style: GoogleFonts.inter(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.greenAccent),
          onPressed: () => _makePhoneCall(phone),
        ),
      ),
    );
  }
}
