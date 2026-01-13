import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:citk_connect/app/routing/settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:citk_connect/home/views/smart_attendance_card.dart';
import 'package:citk_connect/fees/views/fees_card.dart';
import 'package:home_widget/home_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late final bool _isNight;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    _isNight = hour < 6 || hour >= 18;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _updateHomeWidget();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _updateHomeWidget() async {
    try {
      await HomeWidget.saveWidgetData('user', 'Student');
      await HomeWidget.updateWidget(
        name: 'AttendanceWidgetProvider',
        iOSName: 'AttendanceWidget',
      );
    } catch (e) {
      debugPrint("Widget update failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.value;
    final theme = Theme.of(context);

    final accentColor =
        _isNight ? const Color(0xFF6C63FF) : const Color(0xFFFF6B9D);

    final accentGradient = _isNight
        ? [const Color(0xFF6C63FF), const Color(0xFF3F3D56)]
        : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)];

    final String safeName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : "Student";
    final String firstLetter =
        safeName.isNotEmpty ? safeName[0].toUpperCase() : "S";

    return Scaffold(
      backgroundColor:
          _isNight ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: accentGradient,
          ).createShader(bounds),
          child: Text(
            "CITK Connect",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isNight
                      ? [
                          const Color(0xFF0A0E27).withValues(alpha: 0.8),
                          const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          // Animated Notification Bell
          Stack(
            children: [
              IconButton(
                icon: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: accentColor,
                        size: 26,
                      ),
                    );
                  },
                ),
                onPressed: () {
                  context.push('/notices');
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: _isNight ? const Color(0xFF1A1F3A) : Colors.white,
            onSelected: (value) async {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_rounded, color: accentColor),
                  title: Text('My Profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(settingsControllerProvider);
                    final isDark = settings.themeMode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: accentColor,
                      ),
                      title: Text('Dark Mode',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          final target = val ? 'dark' : 'light';
                          context.go('/splash?targetTheme=$target');
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateThemeMode(
                                  val ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeThumbColor: accentColor,
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: Text('Log Out',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      )),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildModernDrawer(
          context, user, safeName, firstLetter, theme, accentColor),
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: _EnhancedBackground(isNight: _isNight),
          ),

          // Main Content
          RefreshIndicator(
            onRefresh: () async {
              setState(() => _isLoading = true);
              await FirebaseAuth.instance.currentUser?.reload();
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _isLoading = false);
            },
            color: accentColor,
            backgroundColor: _isNight ? const Color(0xFF1A1F3A) : Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.3),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            _isNight ? "Good Evening," : "Good Morning,",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Name with animation
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                safeName.split(' ')[0],
                                style: GoogleFonts.poppins(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: accentGradient,
                                    ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 70)),
                                ),
                              ).animate().fadeIn(duration: 600.ms).moveX(
                                  begin: -50,
                                  end: 0,
                                  curve: Curves.easeOutBack),
                            ),
                            const SizedBox(width: 12),
                            AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0,
                                      sin(_floatController.value * 2 * pi) * 5),
                                  child: Text(
                                    "👋",
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Premium Search Bar
                        _buildPremiumSearchBar(accentColor, accentGradient),
                      ],
                    ),
                  ),
                ),

                // Smart Attendance Widget
                const SliverToBoxAdapter(child: SmartAttendanceCard()),

                // Fees & Renewal Card
                const SliverToBoxAdapter(child: FeesCard()),

                // Quick Stats Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        _buildStatCard("85%", "Attendance",
                            Icons.check_circle_outline_rounded, accentColor),
                        const SizedBox(width: 12),
                        _buildStatCard("8.2", "CGPA", Icons.school_rounded,
                            accentGradient[1]),
                        const SizedBox(width: 12),
                        _buildStatCard("12", "Days Left",
                            Icons.calendar_today_rounded, Colors.orangeAccent),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                ),

                // Feature Grid
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildListDelegate(
                      _isLoading
                          ? List.generate(
                              6, (index) => _buildEnhancedSkeleton())
                          : [
                              _buildPremiumFeatureCard(
                                context,
                                title: "Campus Map",
                                icon: Icons.map_rounded,
                                gradient: [
                                  const Color(0xFF667eea),
                                  const Color(0xFF764ba2)
                                ],
                                desc: "Navigate in 3D",
                                index: 0,
                                onTap: () => context.push('/map'),
                              ),
                              _buildPremiumFeatureCard(
                                context,
                                title: "Academics",
                                icon: Icons.school_rounded,
                                gradient: [
                                  const Color(0xFFf093fb),
                                  const Color(0xFFF5576c)
                                ],
                                desc: "Routine & PYQ",
                                index: 1,
                                onTap: () => context.push('/routine'),
                              ),
                              _buildPremiumFeatureCard(
                                context,
                                title: "Bus Tracker",
                                icon: Icons.directions_bus_rounded,
                                gradient: [
                                  const Color(0xFF4facfe),
                                  const Color(0xFF00f2fe)
                                ],
                                desc: "Live Status",
                                index: 2,
                                onTap: () => context.push('/bus-tracker'),
                              ),
                              _buildPremiumFeatureCard(
                                context,
                                title: "AI Assistant",
                                icon: Icons.auto_awesome_rounded,
                                gradient: [
                                  const Color(0xFFfa709a),
                                  const Color(0xFFfee140)
                                ],
                                desc: "Ask anything",
                                index: 3,
                                onTap: () => context.push('/chat'),
                              ),
                              _buildPremiumFeatureCard(
                                context,
                                title: "AR Finder",
                                icon: Icons.view_in_ar_rounded,
                                gradient: [
                                  const Color(0xFF30cfd0),
                                  const Color(0xFF330867)
                                ],
                                desc: "Find Labs",
                                index: 4,
                                onTap: () => context.push('/ar'),
                              ),
                              _buildPremiumFeatureCard(
                                context,
                                title: "Emergency",
                                icon: Icons.local_hospital_rounded,
                                gradient: [
                                  const Color(0xFFff6b6b),
                                  const Color(0xFFc92a2a)
                                ],
                                desc: "SOS & Medical",
                                index: 5,
                                onTap: () => context.push('/emergency'),
                              ),
                            ],
                    ),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSearchBar(Color accentColor, List<Color> gradient) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isNight
              ? [
                  const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                  const Color(0xFF2D3561).withValues(alpha: 0.4),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isNight
              ? Colors.white.withValues(alpha: 0.1)
              : accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradient,
                  ).createShader(bounds),
                  child: const Icon(Icons.search_rounded,
                      size: 24, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Find hostels, labs, or seniors...",
                    style: GoogleFonts.inter(
                      color: _isNight
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isNight
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
            color: _isNight
                ? Colors.white.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _isNight ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _isNight
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSkeleton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isNight
              ? [const Color(0xFF1A1F3A), const Color(0xFF2D3561)]
              : [const Color(0xFFE0E0E0), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: _isNight
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.8),
        );
  }

  Widget _buildPremiumFeatureCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required List<Color> gradient,
    required int index,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isNight
                ? [
                    const Color(0xFF1A1F3A).withValues(alpha: 0.8),
                    const Color(0xFF2D3561).withValues(alpha: 0.6),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.85),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isNight
                ? Colors.white.withValues(alpha: 0.1)
                : gradient[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              children: [
                // Gradient Orb
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          gradient[0].withValues(alpha: 0.3),
                          gradient[1].withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: _isNight ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _isNight
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildModernDrawer(BuildContext context, User? user, String safeName,
      String firstLetter, ThemeData theme, Color accentColor) {
    return Drawer(
      backgroundColor:
          _isNight ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isNight
                    ? [const Color(0xFF6C63FF), const Color(0xFF3F3D56)]
                    : [const Color(0xFFFF6B9D), const Color(0xFFFFA726)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: (user?.photoURL != null &&
                                user!.photoURL!.isNotEmpty)
                            ? CachedNetworkImageProvider(user.photoURL!)
                            : null,
                        child:
                            (user?.photoURL == null || user!.photoURL!.isEmpty)
                                ? Text(
                                    firstLetter,
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      safeName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "No Email",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            title: 'My Profile',
            color: accentColor,
            onTap: () {
              context.pop();
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: Colors.redAccent,
            onTap: () async {
              context.pop();
              await ref.read(authServiceProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _isNight
            ? const Color(0xFF1A1F3A).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.7),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _isNight ? Colors.white : Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Enhanced Background with Particles
class _EnhancedBackground extends StatefulWidget {
  final bool isNight;
  const _EnhancedBackground({required this.isNight});

  @override
  State<_EnhancedBackground> createState() => _EnhancedBackgroundState();
}

class _EnhancedBackgroundState extends State<_EnhancedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  double _parallaxX = 0;
  double _parallaxY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    for (int i = 0; i < 60; i++) {
      _particles.add(_generateParticle());
    }

    _sensorSubscription = accelerometerEventStream().listen(
      (event) {
        if (mounted) {
          setState(() {
            _parallaxX = -event.x * 1.5;
            _parallaxY = event.y * 1.5;
          });
        }
      },
      onError: (e) {},
    );
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 4 + 1,
      speed: _random.nextDouble() * 0.0015 + 0.0005,
      opacity: _random.nextDouble() * 0.6 + 0.2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _EnhancedPainter(
            particles: _particles,
            isNight: widget.isNight,
            parallaxX: _parallaxX,
            parallaxY: _parallaxY,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _EnhancedPainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isNight;
  final double parallaxX;
  final double parallaxY;

  _EnhancedPainter({
    required this.particles,
    required this.isNight,
    required this.parallaxX,
    required this.parallaxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient Background Base
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isNight
            ? [
                const Color(0xFF0A0E27),
                const Color(0xFF1A1F3A),
                const Color(0xFF2D3561),
              ]
            : [
                const Color(0xFFF5F7FA),
                const Color(0xFFE8ECF4),
                const Color(0xFFD6DCE8),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ambient Glows
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      150,
      glowPaint
        ..color = isNight
            ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
            : const Color(0xFFFF6B9D).withValues(alpha: 0.1),
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.6),
      200,
      glowPaint
        ..color = isNight
            ? const Color(0xFF3F3D56).withValues(alpha: 0.1)
            : const Color(0xFFFFA726).withValues(alpha: 0.08),
    );

    // Particles
    for (var particle in particles) {
      particle.y += particle.speed;
      if (particle.y > 1.0) {
        particle.y = 0;
        particle.x = Random().nextDouble();
      }

      final particlePaint = Paint()
        ..color = isNight
            ? Colors.white.withValues(alpha: particle.opacity * 0.4)
            : const Color(0xFF6C63FF).withValues(alpha: particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(
          particle.x * size.width + (parallaxX * particle.size * 0.5),
          particle.y * size.height + (parallaxY * particle.size * 0.5),
        ),
        particle.size,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
