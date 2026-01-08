import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:citk_connect/aspirant/views/aspirant_dashboard.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/map/services/bus_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final updateCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final updatesStreamProvider =
    StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final filter = ref.watch(updateCategoryFilterProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();

  Query query = FirebaseFirestore.instance.collection('updates');
  if (filter != 'All') {
    query = query.where('category', isEqualTo: filter);
  }

  // Fetch more if searching to allow client-side filtering
  final limit = search.isEmpty ? 1 : 20;

  return query
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
    if (search.isEmpty) return snapshot.docs;
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();
      return title.contains(search) || message.contains(search);
    }).toList();
  });
});

final readUpdatesProvider =
    StateNotifierProvider<ReadUpdatesNotifier, Set<String>>((ref) {
  return ReadUpdatesNotifier();
});

class ReadUpdatesNotifier extends StateNotifier<Set<String>> {
  ReadUpdatesNotifier() : super({}) {
    _loadReadUpdates();
  }

  Future<void> _loadReadUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_updates') ?? [];
    state = readList.toSet();
  }

  Future<void> markAsRead(String id) async {
    if (state.contains(id)) return;
    final newState = {...state, id};
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_updates', newState.toList());
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const _StudentDashboard();
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'];

            if (role == 'aspirant') return const AspirantDashboard();
            if (role == 'driver') return const _DriverDashboard();
            if (role == 'faculty') return const _FacultyDashboard();
            return const _StudentDashboard();
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _StudentDashboard(),
    );
  }
}

class _StudentDashboard extends ConsumerWidget {
  const _StudentDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).value;
    final displayName = user?.displayName?.split(' ').first ?? 'Student';
    final readUpdates = ref.watch(readUpdatesProvider);
    final filter = ref.watch(updateCategoryFilterProvider);
    final updatesAsync = ref.watch(updatesStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SnowfallBackground()),
          SafeArea(
            child: SingleChildScrollView(
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
                          const _MorphingHeader(),
                          const SizedBox(height: 4),
                          Text(
                            'Good Morning,',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: user?.photoURL != null
                            ? CachedNetworkImage(
                                imageUrl: user!.photoURL!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.person,
                                        color: Colors.white),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Feature Cards
                  _buildFeatureCard(
                    context,
                    title: 'Bus Tracker',
                    subtitle: 'Live location & ETA',
                    icon: Icons.directions_bus,
                    color: const Color(0xFF6C63FF),
                    onTap: () => context.go('/bus'),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    title: 'AI Assistant',
                    subtitle: 'Ask about exams & hostels',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.orangeAccent,
                    onTap: () => context.go('/chat'),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    title: 'Virtual Tour',
                    subtitle: 'Explore campus in 360°',
                    icon: Icons.video_camera_back_outlined,
                    color: Colors.blueAccent,
                    onTap: () => _launchVirtualTour(context),
                  ),

                  const SizedBox(height: 32),
                  // Search Bar
                  TextField(
                    onChanged: (val) =>
                        ref.read(searchQueryProvider.notifier).state = val,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search updates...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF181B21),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Updates',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Exam', 'Event', 'General'].map((cat) {
                        final isSelected = filter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(updateCategoryFilterProvider.notifier)
                                    .state = cat;
                              }
                            },
                            backgroundColor: const Color(0xFF181B21),
                            selectedColor:
                                const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            labelStyle: GoogleFonts.inter(
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white.withValues(alpha: 0.1)),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  updatesAsync.when(
                    data: (docs) {
                      if (docs.isEmpty && searchQuery.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "No updates found",
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      // 🛡️ Default/Fallback Data (Shows if DB is empty and not searching)
                      if (docs.isEmpty) {
                        return _buildUpdateCard(
                          context,
                          ref,
                          title: 'Early Access',
                          message:
                              'Welcome to the beta version of CITK Connect. More features coming soon!',
                          timestamp: null,
                          docId: null,
                          readUpdates: readUpdates,
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildUpdateCard(
                              context,
                              ref,
                              title: data['title'] ?? 'Update',
                              message: data['message'] ?? '',
                              timestamp: data['timestamp'] as Timestamp?,
                              docId: doc.id,
                              readUpdates: readUpdates,
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const _UpdatesShimmerLoading(),
                    error: (e, _) => Text('Error loading updates',
                        style: GoogleFonts.inter(color: Colors.redAccent)),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.1, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required Timestamp? timestamp,
    required String? docId,
    required Set<String> readUpdates,
  }) {
    final isRead = docId == null || readUpdates.contains(docId);

    return GestureDetector(
      onTap: () {
        if (docId != null) {
          ref.read(readUpdatesProvider.notifier).markAsRead(docId);
        }
        _showUpdateDetails(context, title, message, timestamp);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF181B21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white70,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchVirtualTour(BuildContext context) async {
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

  void _showUpdateDetails(BuildContext context, String title, String message,
      Timestamp? timestamp) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF181B21),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      _formatDate(timestamp),
                      style: GoogleFonts.robotoMono(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF6C63FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF181B21).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdatesShimmerLoading extends StatelessWidget {
  const _UpdatesShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181B21),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Message line 1
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Message line 2
                Container(
                  width: 200,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.05),
                angle: 0.25,
              ),
        );
      }),
    );
  }
}

class _SnowfallBackground extends StatefulWidget {
  const _SnowfallBackground();

  @override
  State<_SnowfallBackground> createState() => _SnowfallBackgroundState();
}

class _SnowfallBackgroundState extends State<_SnowfallBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Snowflake> _snowflakes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    for (int i = 0; i < 50; i++) {
      _snowflakes.add(_generateSnowflake());
    }
  }

  _Snowflake _generateSnowflake() {
    return _Snowflake(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 2 + 1,
      speed: _random.nextDouble() * 0.002 + 0.001,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          for (var flake in _snowflakes) {
            flake.y += flake.speed;
            if (flake.y > 1.0) {
              flake.y = 0.0;
              flake.x = _random.nextDouble();
            }
          }
          return CustomPaint(
            painter: _SnowPainter(_snowflakes),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Snowflake {
  double x;
  double y;
  double size;
  double speed;
  _Snowflake(
      {required this.x,
      required this.y,
      required this.size,
      required this.speed});
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  _SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (var flake in snowflakes) {
      canvas.drawCircle(Offset(flake.x * size.width, flake.y * size.height),
          flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 🚌 DRIVER DASHBOARD (Gen Z Professional)
class _DriverDashboard extends HookConsumerWidget {
  const _DriverDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBroadcasting = useState(false);
    final trafficLevel = useState('LOW');
    final busService = ref.watch(busServiceProvider);

    // 📡 Broadcast Loop (Real GPS)
    useEffect(() {
      StreamSubscription<Position>? positionStream;

      Future<void> startTracking() async {
        // 🛡️ 1. Check & Request Permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }
        if (permission == LocationPermission.deniedForever) return;

        // 🚀 2. Start Real-time Stream
        // High accuracy, but only update if moved > 10 meters (Saves Battery/Data)
        const settings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );

        positionStream =
            Geolocator.getPositionStream(locationSettings: settings)
                .listen((Position position) {
          busService.broadcastLocation(
            'bus_01', // Hardcoded ID for demo
            position.latitude,
            position.longitude,
            position.heading,
            position.speed, // Real speed in m/s
            trafficLevel.value,
            'MED',
          );
        });
      }

      if (isBroadcasting.value) {
        startTracking();
      }
      return () => positionStream?.cancel();
    }, [isBroadcasting.value, trafficLevel.value]);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MorphingHeader(),
              const SizedBox(height: 32),
              Text(
                'Bus Control',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Broadcast your location to students.',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // 🚦 Traffic Condition Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF181B21),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    _TrafficOption(
                      label: 'LOW',
                      color: const Color(0xFF00E676),
                      isSelected: trafficLevel.value == 'LOW',
                      onTap: () => trafficLevel.value = 'LOW',
                    ),
                    _TrafficOption(
                      label: 'MED',
                      color: Colors.orangeAccent,
                      isSelected: trafficLevel.value == 'MED',
                      onTap: () => trafficLevel.value = 'MED',
                    ),
                    _TrafficOption(
                      label: 'HIGH',
                      color: const Color(0xFFFF5252),
                      isSelected: trafficLevel.value == 'HIGH',
                      onTap: () => trafficLevel.value = 'HIGH',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 🔴 Big Red/Green Button
              Center(
                child: GestureDetector(
                  onTap: () {
                    isBroadcasting.value = !isBroadcasting.value;
                  },
                  child: AnimatedContainer(
                    duration: 500.ms,
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBroadcasting.value
                          ? const Color(0xFF00E676).withValues(alpha: 0.1)
                          : const Color(0xFFFF5252).withValues(alpha: 0.1),
                      border: Border.all(
                        color: isBroadcasting.value
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF5252),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isBroadcasting.value
                              ? const Color(0xFF00E676).withValues(alpha: 0.3)
                              : const Color(0xFFFF5252).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isBroadcasting.value
                              ? Icons.wifi_tethering
                              : Icons.wifi_tethering_off,
                          size: 48,
                          color: isBroadcasting.value
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF5252),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isBroadcasting.value ? 'ON AIR' : 'OFFLINE',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ), // Closing parenthesis for Padding
    );
  }
}

class _TrafficOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrafficOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🎓 FACULTY DASHBOARD (Gen Z Professional)
class _FacultyDashboard extends StatelessWidget {
  const _FacultyDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MorphingHeader(),
              const SizedBox(height: 32),
              Text(
                'Admin Console',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // 📢 Broadcast Card
              GestureDetector(
                onTap: () => context.push('/admin/post-update'),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign, color: Colors.white),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast Notice',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Send alerts to all students',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorphingHeader extends StatefulWidget {
  const _MorphingHeader();

  @override
  State<_MorphingHeader> createState() => _MorphingHeaderState();
}

class _MorphingHeaderState extends State<_MorphingHeader> {
  int _index = 0;
  Timer? _timer;
  final List<String> _texts = ["CITK CONNECT", "CODELITH LABS"];

  @override
  void initState() {
    super.initState();
    // Toggle text every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _index = (_index + 1) % _texts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.5), // Slide up slightly
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
      child: Text(
        _texts[_index],
        key: ValueKey<String>(_texts[_index]), // Key triggers animation
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: const Color(0xFF6C63FF), // Periwinkle Accent
        ),
      ),
    );
  }
}
