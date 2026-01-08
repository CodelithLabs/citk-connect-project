import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class AspirantDashboard extends ConsumerWidget {
  const AspirantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Loading..."));
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final dept = data?['department'] ?? 'General';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Aspirant',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF2C2C2C),
                            child: Icon(Icons.school, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Department Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4842A8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Interest',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dept,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _launchSyllabus(context, dept),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'View Syllabus & Faculty',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .shimmer(
                                      duration: 2000.ms,
                                      color:
                                          Colors.white.withValues(alpha: 0.3))
                                  .scale(
                                      end: const Offset(1.05, 1.05),
                                      duration: 2000.ms),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildActionCard(context, 'Campus Map',
                              Icons.map_outlined, Colors.orangeAccent),
                          _buildActionCard(
                              context,
                              'Virtual Tour',
                              Icons.video_camera_back_outlined,
                              Colors.blueAccent,
                              onTap: () => _launchVirtualTour(context)),
                          _buildActionCard(context, 'Admission',
                              Icons.article_outlined, Colors.greenAccent),
                          _buildActionCard(
                              context,
                              'Ask AI',
                              Icons.chat_bubble_outline,
                              const Color(0xFF6C63FF),
                              onTap: () => context.go('/chat')),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Future<void> _launchSyllabus(BuildContext context, String dept) async {
    // 📄 Demo PDF Links (Replace with real Firestore data later)
    final Map<String, String> syllabusLinks = {
      'CSE': 'https://cit.ac.in/images/pdf/syllabus/CSE_Syllabus.pdf',
      'ECE': 'https://cit.ac.in/images/pdf/syllabus/ECE_Syllabus.pdf',
      'FET': 'https://cit.ac.in/images/pdf/syllabus/FET_Syllabus.pdf',
    };

    final url = syllabusLinks[dept] ?? 'https://cit.ac.in/academics';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Syllabus not found for $dept')),
          );
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _launchVirtualTour(BuildContext context) async {
    // 🎥 Launching external video for best performance (Gen Z prefers native YouTube app)
    final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=CIT+Kokrajhar+Campus+Drone+View');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load Virtual Tour')),
          );
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Widget _buildActionCard(
      BuildContext context, String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181B21),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
