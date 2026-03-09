import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:citk_connect/fees/views/fees_card.dart';
import 'package:home_widget/home_widget.dart';
import 'package:citk_connect/profile/views/profile_screen.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:citk_connect/mail/views/inbox_screen.dart';

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
  int _selectedIndex = 0;

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

    // Navigation Destinations
    final List<Widget> screens = [
      _buildHomeDashboard(
          context, safeName, firstLetter, accentColor, accentGradient),
      const Center(
          child: Text("Bus Tracker Placeholder")), // Replace with BusScreen()
      const InboxScreen(),
      const ProfileScreen(),
    ];

    // Instead of returning a Scaffold, just return the body content for the selected tab
    // The parent Scaffold will provide appBar, navigationBar, drawer, etc.
    return SafeArea(
      child: screens[_selectedIndex],
    );
  }

  Widget _buildHomeDashboard(BuildContext context, String safeName,
      String firstLetter, Color accentColor, List<Color> accentGradient) {
    return Stack(
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
                                begin: -50, end: 0, curve: Curves.easeOutBack),
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

              // Next Class Card (New Feature)
              SliverToBoxAdapter(child: _buildNextClassCard(accentColor)),

              // Quick Actions Row (New Feature)
              SliverToBoxAdapter(child: _buildQuickActionsRow(accentColor)),

              // Fees & Renewal Card
              const SliverToBoxAdapter(child: FeesCard()),

              // Quick Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildListDelegate(
                    _isLoading
                        ? List.generate(6, (index) => _buildEnhancedSkeleton())
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
                              onTap: () => context.push('/bus'),
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
    );
  }

  Widget _buildNextClassCard(Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isNight
              ? [
                  const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  const Color(0xFF6C63FF).withValues(alpha: 0.05)
                ]
              : [const Color(0xFF6C63FF).withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("NEXT CLASS",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              Text("In 15 mins",
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text("Data Structures & Algorithms",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isNight ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text("Room 304, Academic Block 1",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildQuickActionsRow(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionBtn(
              "Bus Status",
              Icons.directions_bus_filled_rounded,
              Colors.blueAccent,
              () => setState(() => _selectedIndex = 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionBtn(
              "Check Mail",
              Icons.mail_rounded,
              Colors.orangeAccent,
              () => setState(() => _selectedIndex = 2),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickActionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _isNight ? Colors.white : Colors.black87)),
          ],
        ),
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
              Navigator.pop(context); // Close drawer
              setState(() => _selectedIndex = 3); // Switch to Profile
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

// ==========================================
// DATA: STRUCTURED NOTICES
// ==========================================
final List<Map<String, String>> noticeData = [
  {
    "title": "Registrations Now Open | CITK MUN 2026",
    "date": "Jan 10, 2026",
    "sender": "CITK MODEL UNITED NATIONS",
    "body":
        "Greetings from the CITK Model United Nations Secretariat! We are delighted to announce that registrations are now officially open for CITK MUN 2026. Dates: 23rd-25th Jan 2026. Venue: CIT Kokrajhar. Outstanding performers will be honored with Certificates, Trophies, and Exciting Gifts."
  },
  {
    "title": "Power Supply Restored",
    "date": "Jan 10, 2026",
    "sender": "Electrical Team CITK",
    "body":
        "Power supply has been restored to the campus following the scheduled interruption for urgent repair at 132 kV GSS, Adabari. Thank you for your patience and support."
  },
  {
    "title": "DD Robocon India 2026 Outreach",
    "date": "Jan 8, 2026",
    "sender": "Dean Alumni and External Relations",
    "body":
        "STPI in association with Prasar Bharti and IIT Delhi is organizing DD Robocon India 2026. The winner will represent India at the ABU Robocon in Hong Kong. Pre-registration deadline: 9 January 2026."
  }
];

// ==========================================
// DATA: ROUTINE
// ==========================================
final Map<String, dynamic> routineData = {
  // ==========================================
  // MONDAY
  // ==========================================
  "MONDAY": {
    "M.Tech_M.Des_II": {
      "CSE": {
        "room": "PG Class Room",
        "slots": [
          "",
          "MCS218:BKC",
          "MCS201:AN",
          "MCS202:HKK",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "WRH": {
        "room": "PG ROOM",
        "slots": [
          "",
          "MCE201:SMJ",
          "MCE202:SMJ",
          "MCE2101:AVP",
          "Lunch Break",
          "MCE2108:MMG",
          "",
          ""
        ]
      },
      "GET": {
        "room": "PG Class Room",
        "slots": [
          "",
          "MGE214",
          "",
          "MGE202: RKR",
          "Lunch Break",
          "",
          "Energy Lab II",
          ""
        ]
      },
      "FET": {
        "room": "PG Class Room",
        "slots": [
          "",
          "",
          "MFE203: ABD",
          "MFE2122: SKR",
          "Lunch Break",
          "MFE2111: SSM",
          "SEMINAR-I: MFE291: RDK/SBR",
          ""
        ]
      },
      "DESIGN": {
        "room": "",
        "slots": [
          "",
          "LAB:MMD 211:SDN",
          "",
          "LAB:MMD:212:NF",
          "Lunch Break",
          "",
          "",
          ""
        ]
      }
    },
    "M.Tech_M.Des_IV": {
      "CSE": {
        "room": "PG Class Room",
        "slots": ["", "", "Project Lab", "", "Lunch Break", "", "", ""]
      },
      "WRH": {
        "room": "",
        "slots": [
          "",
          "",
          "Project",
          "",
          "Lunch Break",
          "Project",
          "Project",
          ""
        ]
      },
      "GET": {
        "room": "",
        "slots": ["", "", "Project", "", "Lunch Break", "Project", "", ""]
      },
      "FET": {
        "room": "",
        "slots": ["", "", "", "", "Lunch Break", "", "", ""]
      },
      "DESIGN": {
        "room": "",
        "slots": ["", "", "", "", "Lunch Break", "", "", ""]
      }
    },
    "Diploma_Sem_II": {
      "ET_CT_FP": {
        "room": "231",
        "slots": [
          "DME201: HDM",
          "DPH201:MBB",
          "DMA201-AAB",
          "DCH201(ANK/ARM)",
          "Lunch Break",
          "DCSE201:PKS",
          "DME 271: HDM/SJI/MNG/SBS",
          ""
        ]
      },
      "CO_CI_AM": {
        "room": "232",
        "slots": [
          "",
          "DCSE201:APS",
          "DPH201:MB",
          "DMA201-JKK",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "AM": {
        "room": "",
        "slots": [
          "",
          "",
          "DMD201:DKB",
          "LAB:DMD271:DKB",
          "Lunch Break",
          "DMD202:BKS",
          "LAB:DMD272:BKS",
          ""
        ]
      }
    },
    "Diploma_Sem_IV": {
      "ET": {
        "room": "125",
        "slots": [
          "DEC 401 ATP",
          "DEC404 PKM",
          "DEC471 ATP",
          "",
          "Lunch Break",
          "DHS401:TNK/MDB (231)",
          "DEC415 KKP",
          ""
        ]
      },
      "CE": {
        "room": "119",
        "slots": [
          "",
          "",
          "",
          "DCE404:NLD",
          "Lunch Break",
          "DHS401:TNK/MDB (231)",
          "DCE403:JKB",
          "DCE401: OMP"
        ]
      },
      "FP": {
        "room": "235",
        "slots": [
          "",
          "DME 401: HDM",
          "DIE405:BRB",
          "DFE402: ANI",
          "Lunch Break",
          "DHS401:TNK/MDB (231)",
          "Lab: DFE473 (L): ANI/PKN",
          ""
        ]
      },
      "CO": {
        "room": "",
        "slots": [
          "",
          "DCS402:AKB (304)",
          "DCS405:MTK (304)",
          "DCS401:TNS (304)",
          "Lunch Break",
          "DIE403: DPS",
          "DCS471 Lab:TNS (CSE Lab4)",
          ""
        ]
      },
      "CI": {
        "room": "303",
        "slots": [
          "DEE401(DTS)",
          "DIE402:JTD",
          "DIE401: DPD",
          "",
          "Lunch Break",
          "DIE403: DPS",
          "DIE474: AKR, BPC",
          ""
        ]
      },
      "AM": {
        "room": "",
        "slots": [
          "",
          "DAMT404:SDN",
          "LAB:DAMT474:SDN",
          "",
          "Lunch Break",
          "LAB:DAMT472:NF",
          "",
          ""
        ]
      }
    },
    "Diploma_Sem_VI": {
      "ET": {
        "room": "125",
        "slots": [
          "",
          "DECE695 KKP",
          "DECE604: JDHB",
          "DECE601 BBP",
          "Lunch Break",
          "DHSS602: KSB",
          "",
          ""
        ]
      },
      "CE": {
        "room": "119",
        "slots": [
          "DCE603:NLD",
          "DCE612:AVP",
          "DCE602:JKB",
          "",
          "Lunch Break",
          "",
          "DCE679",
          ""
        ]
      },
      "FP": {
        "room": "235",
        "slots": [
          "",
          "DFET691:PROJECT",
          "",
          "",
          "Lunch Break",
          "DFET612: ABD",
          "DFET691:PROJECT",
          ""
        ]
      },
      "CO": {
        "room": "",
        "slots": [
          "",
          "",
          "DCSE612:PPS (236)",
          "DCSE613:BKC (236)",
          "Lunch Break",
          "DHSS601: PBC (304)",
          "",
          ""
        ]
      },
      "CI": {
        "room": "303",
        "slots": [
          "",
          "Project : DIE691",
          "",
          "DEE611(DTS)",
          "Lunch Break",
          "DHSS601: PBC (304)",
          "DIE601: SWK",
          ""
        ]
      },
      "AM": {
        "room": "",
        "slots": [
          "",
          "",
          "",
          "",
          "Lunch Break",
          "DHSS601: PBC (304)",
          "DAMT601:SBR",
          "LAB:DAMT671:SBR"
        ]
      }
    },
    "Degree_Sem_II": {
      "ECE_IE": {
        "room": "126",
        "slots": [
          "UMA201-SDB",
          "UHS201: BHB",
          "UCSE201:DKR",
          "UME 201 : SRB",
          "Lunch Break",
          "",
          "UHS202:JDHB",
          ""
        ]
      },
      "CSE_G2": {
        "room": "G2",
        "slots": [
          "",
          "",
          "UMA201-SMD",
          "UHS202:JDHB",
          "Lunch Break",
          "UCSE201:AKB",
          "UCSE271 Lab:AKB (CSE Lab2)",
          ""
        ]
      },
      "CE_FET_G1": {
        "room": "G1",
        "slots": [
          "UHS201: BHB",
          "UME 201 : SRB",
          "UCH201(GND/PJK)",
          "UMA201-SDB/SMD",
          "Lunch Break",
          "UCSE201:DKR",
          "",
          ""
        ]
      },
      "MCD": {
        "room": "",
        "slots": [
          "UMD 203:ABP",
          "",
          "",
          "LAB:UMD 273:ABP",
          "Lunch Break",
          "",
          "STUDIO:UMD 294:ABP",
          ""
        ]
      }
    },
    "Degree_Sem_IV": {
      "ECE": {
        "room": "123",
        "slots": [
          "",
          "UEC401 NMD",
          "UHS401:KSB",
          "",
          "Lunch Break",
          "UECE491 NMD",
          "",
          ""
        ]
      },
      "IE": {
        "room": "227",
        "slots": [
          "",
          "UEE401(RJD)",
          "UIE402: JTD",
          "UIE401: KDS",
          "Lunch Break",
          "UIE471: KDS, APN",
          "",
          ""
        ]
      },
      "CSE_A": {
        "room": "",
        "slots": [
          "",
          "",
          "UMA401-GCR (229)",
          "UCS401:RJP (230)",
          "Lunch Break",
          "UCS403:MTK (230)",
          "UHS471Lab: TNK/BHB/MLB",
          ""
        ]
      },
      "CSE_B": {
        "room": "",
        "slots": [
          "",
          "UCS401:RJP (229)",
          "UMA401-GCR (229)",
          "UHS401:KSB (229)",
          "Lunch Break",
          "UCS471 Lab:RJP (CSE Lab1)",
          "UCS403:MTK (229)",
          ""
        ]
      },
      "CE": {
        "room": "121",
        "slots": [
          "",
          "",
          "",
          "UHS401:PBC",
          "Lunch Break",
          "UCE402:ABD",
          "UCE404:AKD",
          "UCE401:YCO"
        ]
      },
      "FET": {
        "room": "233",
        "slots": [
          "",
          "UFE412: ANI",
          "UHS401:PBC",
          "UFE403: AVM",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "MCD": {
        "room": "",
        "slots": [
          "",
          "UMCD 401:BKS",
          "LAB:UMCD 471:BKS",
          "",
          "Lunch Break",
          "STUDIO:UMCD 491:SDN",
          "LAB:UMCD472:NF",
          ""
        ]
      }
    },
    "Degree_Sem_VI": {
      "ECE": {
        "room": "124",
        "slots": [
          "",
          "UECE601 AGM",
          "UECE602 BBP",
          "UECE616 HDC/RJC (R-123/124)",
          "Lunch Break",
          "UECE671 AGM",
          "",
          ""
        ]
      },
      "IE": {
        "room": "301",
        "slots": [
          "",
          "UIE601: RKR",
          "UIE611: KDS",
          "UIE602: DPD",
          "Lunch Break",
          "UIE612: AKR",
          "",
          ""
        ]
      },
      "CSE_A": {
        "room": "",
        "slots": [
          "",
          "UHSS601: MDB (228)",
          "UCSE602:PSB (228)",
          "",
          "Lunch Break",
          "UCSE601:RNM (228)",
          "",
          ""
        ]
      },
      "CSE_B": {
        "room": "",
        "slots": [
          "",
          "UCSE671 Lab:RNM (CSE Lab2)",
          "UHSS601: MDB (228)",
          "UCSE602:PSB (229)",
          "Lunch Break",
          "UCSE601:RNM (229)",
          "",
          ""
        ]
      },
      "CE": {
        "room": "122",
        "slots": [
          "",
          "UCE672:BRS,SMP(A)/UCE671:AKD,AJD/KHS(B)",
          "UCE603:AKD",
          "UCE602:RMH",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "FET": {
        "room": "234",
        "slots": [
          "",
          "UFET601:SKR",
          "UIE604: RKR",
          "UFET612: MAG",
          "Lunch Break",
          "",
          "Lab: UIE674(L): RKR/ANB",
          ""
        ]
      },
      "MCD": {
        "room": "",
        "slots": [
          "",
          "",
          "",
          "UMCD 604:DKB",
          "Lunch Break",
          "LAB:UMCD 674:DKB",
          "",
          ""
        ]
      }
    },
    "Degree_Sem_VIII": {
      "ECE": {
        "room": "124",
        "slots": [
          "",
          "UECE895",
          "UECE811A SNB",
          "UECE812A ADM",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "IE": {
        "room": "301/227",
        "slots": [
          "",
          "Project Lab",
          "UIE811: TKM",
          "UIE818/ UIE819 (301)/ UIE820 (227)",
          "Lunch Break",
          "Project Lab",
          "",
          ""
        ]
      },
      "CSE_A": {
        "room": "",
        "slots": [
          "",
          "Project Lab",
          "Project Lab",
          "UCSE812:BKC (228)",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "CSE_B": {
        "room": "",
        "slots": [
          "",
          "Project Lab",
          "Project Lab",
          "UCSE814:PPS (230)",
          "Lunch Break",
          "",
          "",
          ""
        ]
      },
      "CE": {
        "room": "122",
        "slots": [
          "UCE802:BRS",
          "UCE801:OMP",
          "UCE816:RMH",
          "",
          "Lunch Break",
          "UCE891",
          "",
          ""
        ]
      },
      "FET": {
        "room": "234",
        "slots": [
          "",
          "UFET891: MAJOR PROJECT-II",
          "",
          "",
          "Lunch Break",
          "UFET801: MAG",
          "UFET811: SBR",
          ""
        ]
      },
      "MCD": {
        "room": "",
        "slots": [
          "",
          "",
          "",
          "Elective-V:UMCD 811 :ABP",
          "Lunch Break",
          "",
          "",
          ""
        ]
      }
    }
  },
  // ==========================================
  // TUESDAY (Copy of Monday so it's not empty)
  // ==========================================
  "TUESDAY": {
    "Diploma_Sem_IV": {
      "CO": {
        "room": "",
        "slots": [
          "DCS402:AKB",
          "DCS405:MTK",
          "Lab",
          "Lunch Break",
          "DIE403: DPS",
          "",
          "",
          ""
        ]
      }
    },
    // ... Copy other Monday items here if needed
  }
};
