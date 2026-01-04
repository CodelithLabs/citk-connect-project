import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const kBackgroundColor = Color(0xFF0F1115);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "SETTINGS",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("MY CHOICES"),
          _buildSwitchTile(
              "Dark Mode", "Always on for Gen Z vibe", true, (val) {}),
          _buildSwitchTile(
              "Notifications", "Get updates on bus & classes", true, (val) {}),
          const SizedBox(height: 24),
          _buildSectionHeader("SUPPORT"),
          _buildActionTile("Report a Bug", Icons.bug_report_outlined, () {}),
          _buildActionTile("Privacy Policy", Icons.lock_outline, () {}),
          _buildActionTile(
              "Terms of Service", Icons.description_outlined, () {}),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "CITK Connect v1.0.0\nCode Lith Labs",
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF6C63FF),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        activeTrackColor: const Color(0xFF6C63FF),
        thumbColor: WidgetStateProperty.all(Colors.white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.2), size: 14),
      ),
    );
  }
}
