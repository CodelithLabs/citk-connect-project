import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:citk_connect/app/app.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/common/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final biometricsEnabledProvider = StateProvider<bool>((ref) => false);
final autoSyncProvider = StateProvider<bool>((ref) => true);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isEditMode = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isEditMode ? Icons.check_rounded : Icons.edit_rounded,
                size: 20,
                color: const Color(0xFF6C63FF),
              ),
            ),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
              if (!_isEditMode) {
                // Save changes
                _saveProfile();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded,
                      size: 80, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text(
                    "Not logged in",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildProfileContent(user, ref, isDark);
        },
        loading: () => _buildLoadingSkeleton(isDark),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                "Error loading profile",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Profile Image Skeleton
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1500.ms,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: 24),
            // Name Skeleton
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
            const SizedBox(height: 12),
            // Email Skeleton
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(User user, WidgetRef ref, bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}",
                style: GoogleFonts.inter(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return _buildLoadingSkeleton(isDark);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final name = data?['displayName'] ?? user.displayName ?? "Unknown User";
        final email = data?['email'] ?? user.email ?? "";
        final role = (data?['role'] as String?)?.toUpperCase() ?? "STUDENT";
        final phone = data?['phone'] ?? "+91 XXXXXXXXXX";
        final rollNo = data?['rollNo'] ?? "CSE/2023/XXX";
        final semester = data?['semester'] ?? "6th Semester";
        final photoUrl = user.photoURL;

        _nameController.text = name;
        _phoneController.text = phone;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Hero Header with Gradient
              _buildHeroHeader(user, name, email, role, photoUrl, isDark),

              // Stats Cards
              _buildStatsSection(isDark),

              // Personal Info
              _buildPersonalInfo(name, email, phone, rollNo, semester, isDark),

              // Quick Actions
              _buildQuickActions(isDark),

              // Settings Section
              _buildSettingsSection(ref, isDark),

              // Activity Section
              _buildActivitySection(isDark),

              // Danger Zone
              _buildDangerZone(ref, isDark),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(User user, String name, String email, String role,
      String? photoUrl, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF6C63FF), const Color(0xFF3F3D56)]
              : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Profile Image with Border
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: photoUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoUrl == null
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "U",
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6C63FF),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isEditMode)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImageOptions(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            // Name
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            // Email
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).scale(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1A1F3A).withValues(alpha: 0.95),
                      const Color(0xFF2D3561).withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      "85%",
                      "Attendance",
                      Icons.check_circle_rounded,
                      const Color(0xFF4CAF50),
                      isDark),
                  Container(
                    width: 1,
                    height: 50,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  _buildStatItem("8.2", "CGPA", Icons.school_rounded,
                      const Color(0xFF6C63FF), isDark),
                  Container(
                    width: 1,
                    height: 50,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  _buildStatItem("12", "Projects", Icons.folder_rounded,
                      const Color(0xFFFF9800), isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(String name, String email, String phone,
      String rollNo, String semester, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                        const Color(0xFF2D3561).withValues(alpha: 0.4),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                _buildInfoTile("Full Name", name, Icons.person_rounded, isDark,
                    isEditable: true),
                _buildDivider(isDark),
                _buildInfoTile(
                    "Email Address", email, Icons.email_rounded, isDark),
                _buildDivider(isDark),
                _buildInfoTile(
                    "Phone Number", phone, Icons.phone_rounded, isDark,
                    isEditable: true),
                _buildDivider(isDark),
                _buildInfoTile(
                    "Roll Number", rollNo, Icons.badge_rounded, isDark),
                _buildDivider(isDark),
                _buildInfoTile(
                    "Semester", semester, Icons.calendar_today_rounded, isDark),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoTile(String label, String value, IconData icon, bool isDark,
      {bool isEditable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable && _isEditMode)
            Icon(Icons.edit_rounded,
                size: 18,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionCard("View\nRoutine", Icons.calendar_month_rounded,
                  const Color(0xFF6C63FF), isDark, () {}),
              const SizedBox(width: 12),
              _buildActionCard("Download\nID Card", Icons.badge_rounded,
                  const Color(0xFFFF6B9D), isDark, () {}),
              const SizedBox(width: 12),
              _buildActionCard("Academic\nHistory", Icons.school_rounded,
                  const Color(0xFF4CAF50), isDark, () {}),
              const SizedBox(width: 12),
              _buildActionCard(
                  "Digital\nLocker",
                  Icons.folder_special_rounded,
                  const Color(0xFFFF9800),
                  isDark,
                  () => context.push('/profile/locker')),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionCard(String title, IconData icon, Color color, bool isDark,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                      const Color(0xFF2D3561).withValues(alpha: 0.4),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Preferences",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                        const Color(0xFF2D3561).withValues(alpha: 0.4),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isEnabled = themeMode == ThemeMode.dark;
                    return _buildSwitchTile(
                      "Dark Mode",
                      "Reduce eye strain at night",
                      Icons.dark_mode_rounded,
                      isEnabled,
                      isDark,
                      (val) => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(val ? ThemeMode.dark : ThemeMode.light),
                    );
                  },
                ),
                _buildDivider(isDark),
                Consumer(
                  builder: (context, ref, child) {
                    final isEnabled = ref.watch(notificationsEnabledProvider);
                    return _buildSwitchTile(
                      "Notifications",
                      "Get updates about classes & events",
                      Icons.notifications_rounded,
                      isEnabled,
                      isDark,
                      (val) {
                        ref.read(notificationsEnabledProvider.notifier).state =
                            val;
                        final notifService =
                            ref.read(notificationServiceProvider);
                        if (val) {
                          notifService.subscribeToUpdates();
                        } else {
                          notifService.unsubscribeFromUpdates();
                        }
                      },
                    );
                  },
                ),
                _buildDivider(isDark),
                Consumer(
                  builder: (context, ref, child) {
                    final isEnabled = ref.watch(biometricsEnabledProvider);
                    return _buildSwitchTile(
                      "Biometric Login",
                      "Use fingerprint or face ID",
                      Icons.fingerprint_rounded,
                      isEnabled,
                      isDark,
                      (val) => ref
                          .read(biometricsEnabledProvider.notifier)
                          .state = val,
                    );
                  },
                ),
                _buildDivider(isDark),
                Consumer(
                  builder: (context, ref, child) {
                    final isEnabled = ref.watch(autoSyncProvider);
                    return _buildSwitchTile(
                      "Auto-Sync",
                      "Sync data automatically",
                      Icons.sync_rounded,
                      isEnabled,
                      isDark,
                      (val) => ref.read(autoSyncProvider.notifier).state = val,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      bool value, bool isDark, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            "Attendance Marked",
            "Data Structures - 85%",
            Icons.check_circle_rounded,
            const Color(0xFF4CAF50),
            "2 hours ago",
            isDark,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            "Assignment Submitted",
            "Operating Systems Lab",
            Icons.assignment_turned_in_rounded,
            const Color(0xFF6C63FF),
            "Yesterday",
            isDark,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            "Fee Payment",
            "Semester Fee - ₹45,000",
            Icons.payment_rounded,
            const Color(0xFFFF9800),
            "3 days ago",
            isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon,
      Color color, String time, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                  const Color(0xFF2D3561).withValues(alpha: 0.4),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danger Zone",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                        const Color(0xFF2D3561).withValues(alpha: 0.4),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildDangerTile(
                  "Clear Cache",
                  "Free up storage space",
                  Icons.delete_sweep_rounded,
                  isDark,
                  () => _showClearCacheDialog(),
                ),
                _buildDivider(isDark),
                _buildDangerTile(
                  "Deactivate Account",
                  "Temporarily disable your account",
                  Icons.block_rounded,
                  isDark,
                  () => _showDeactivateDialog(),
                ),
                _buildDivider(isDark),
                _buildDangerTile(
                  "Sign Out",
                  "Log out from this device",
                  Icons.logout_rounded,
                  isDark,
                  () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDangerTile(String title, String subtitle, IconData icon,
      bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      indent: 20,
      endIndent: 20,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1F3A),
                        const Color(0xFF2D3561),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF5F7FA),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign Out?',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to log out from your account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(authServiceProvider.notifier).signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1F3A), const Color(0xFF2D3561)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_sweep_rounded,
                    color: Colors.orangeAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Clear Cache?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will clear 127 MB of cached data',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.inter()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performCacheClear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Clear',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1F3A), const Color(0xFF2D3561)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Deactivate Account?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account will be temporarily disabled. You can reactivate anytime.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.inter()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Deactivate',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1A1F3A), const Color(0xFF0A0E27)]
                  : [Colors.white, const Color(0xFFF5F7FA)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Change Profile Picture',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildImageOption(
                  Icons.camera_alt_rounded, 'Take Photo', isDark, () {}),
              const SizedBox(height: 12),
              _buildImageOption(Icons.photo_library_rounded,
                  'Choose from Gallery', isDark, () {}),
              const SizedBox(height: 12),
              _buildImageOption(
                  Icons.delete_rounded, 'Remove Photo', isDark, () {},
                  isDestructive: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
      IconData icon, String label, bool isDark, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isDestructive ? Colors.redAccent : const Color(0xFF6C63FF)),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive
                    ? Colors.redAccent
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    // Implement save logic
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _performCacheClear() {
    // Simulate cache clearing
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache cleared - 127 MB freed',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
