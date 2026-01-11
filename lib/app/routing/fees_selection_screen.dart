import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FeesSelectionScreen extends StatelessWidget {
  const FeesSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Fees & Renewal', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Portal",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 8),
            Text(
              "Access official CITK payment and renewal services securely.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // SBI Collect Card
            _buildPortalCard(
              context,
              title: "SBI Collect",
              description: "Pay semester fees, hostel fees, and other dues.",
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF283593), // SBI Blue
              url: "https://onlinesbi.sbi.bank.in/sbicollect/",
              isDark: isDark,
              delay: 200,
            ),

            const SizedBox(height: 20),

            // Renewal Card
            _buildPortalCard(
              context,
              title: "CITK Renewal",
              description: "Semester registration and hostel renewal portal.",
              icon: Icons.autorenew_rounded,
              color: const Color(0xFFE65100), // Orange accent
              url: "https://renewal.cit.ac.in/",
              isDark: isDark,
              delay: 300,
            ),

            const SizedBox(height: 40),

            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F3A) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.blue.shade100,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Secure Browser",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "Use the built-in password generator in the top bar for enhanced security.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String url,
    required bool isDark,
    required int delay,
  }) {
    return InkWell(
      onTap: () {
        context.push(
          '/webview?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(title)}',
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)]
                : [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}
