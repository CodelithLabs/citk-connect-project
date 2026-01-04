import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:citk_connect/auth/services/auth_service.dart';

class ImprovedProfileView extends ConsumerWidget {
  const ImprovedProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.value;

    // Theme Constants from AI_CONTEXT
    const kBackgroundColor = Color(0xFF0F1115);
    const kCardColor = Color(0xFF181B21);
    final kAccentColor = const Color(0xFF6C63FF); // Periwinkle Blue

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        // Clean Leading Icon (Back or Empty) - Fixes "Left Dot" issue
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          "PROFILE",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        // Clean Actions - Single Settings Icon - Fixes "Right Dot" issue
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // Navigate to the new Settings Page
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar with Glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAccentColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: kCardColor,
                backgroundImage: (user?.photoURL != null)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL == null)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 16),

            // Name & Role
            Text(
              user?.displayName ?? "Guest User",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),

            Text(
              "Computer Science & Engineering",
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 30),

            // Menu Items
            _buildProfileTile(
              icon: Icons.person_outline,
              title: "Personal Details",
              subtitle: "Edit your info",
              color: kCardColor,
              onTap: () {},
            ),
            _buildProfileTile(
              icon: Icons.school_outlined,
              title: "Academic History",
              subtitle: "Grades & Attendance",
              color: kCardColor,
              onTap: () {},
            ),
            _buildProfileTile(
              icon: Icons.logout,
              title: "Logout",
              subtitle: "Sign out of device",
              color: kCardColor,
              isDestructive: true,
              onTap: () {
                ref.read(authServiceProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isDestructive ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withValues(alpha: 0.2),
          size: 14,
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}
