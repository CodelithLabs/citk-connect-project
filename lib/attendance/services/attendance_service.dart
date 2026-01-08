import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 📦 IMPORTS
import '../../auth/services/auth_service.dart';
import '../../attendance/models/class_session.dart';

// -----------------------------------------------------------------------------
// 🛠️ ATTENDANCE SERVICE
// -----------------------------------------------------------------------------
final attendanceServiceProvider = Provider<AttendanceService>((ref) => AttendanceService());

class AttendanceService {
  Stream<Map<int, List<ClassSession>>> streamTimetable(String batchId) {
    // TODO: Replace with actual Firestore stream
    return Stream.value({});
  }

  Future<void> uploadMockTimetable(String batchId) async {
    debugPrint("Uploading mock timetable for $batchId");
  }

  Future<void> updateClassSession(String batchId, int day, ClassSession session) async {
    // TODO: Implement actual Firestore update logic
    debugPrint("Updating session: ${session.subject} in room ${session.room}");
  }
}

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _selectedIndex = 0;

  // 🗓️ HELPER: Get today's weekday (1=Mon, 7=Sun)
  int get _today => DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    // 🛠️ HACK: Run this ONCE to seed your database, then delete this line.
    // Future.delayed(Duration.zero, () {
    //   ref.read(attendanceServiceProvider).uploadMockTimetable("2025_CSE"); 
    // });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authServiceProvider);
    final user = userAsync.valueOrNull;
    
    // 🛡️ Fail-safe: If user is null (rare), show loading
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 🕵️ INTER-CONNECTIVITY: Construct Batch ID (e.g., "2025_CSE")
    // In a real app, you get this from the CITParsedData stored in Firestore.
    // For the Hackathon, we can infer it or hardcode a fallback.
    final batchId = "2025_CSE"; // TODO: Fetch from Firestore User Profile

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      
      // 📱 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ""),
              backgroundColor: const Color(0xFF4285F4),
              child: user.photoURL == null ? Text(user.displayName?[0] ?? "U") : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user.displayName?.split(' ')[0]} 👋",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "CSE • 2025 Batch", // Dynamic data here later
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {}, // Open Notices
          ),
        ],
      ),

      // 📱 BOTTOM NAV
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF4285F4).withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'AI Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),

      // 📱 BODY (Switchable)
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(batchId),
          const Center(child: Text("Full Calendar UI Coming Soon")), // Placeholder
          const Center(child: Text("Gemini Chat UI Coming Soon")),   // Placeholder
          const Center(child: Text("Profile UI Coming Soon")),       // Placeholder
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏠 TAB 1: SMART HOME
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab(String batchId) {
    final attendanceService = ref.watch(attendanceServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SMART ATTENDANCE CARD
          _buildAttendanceCard(),

          const SizedBox(height: 24),
          
          // 2. LIVE BUS TRACKER TEASER
          _buildLiveBusCard(),

          const SizedBox(height: 24),

          // 3. TODAY'S CLASSES (Streamed from Firestore)
          Text("Today's Schedule", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          StreamBuilder<Map<int, List<ClassSession>>>(
            stream: attendanceService.streamTimetable(batchId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LinearProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildErrorCard("Could not load schedule");
              }

              final weeklyData = snapshot.data ?? {};
              final todaysClasses = weeklyData[_today] ?? [];

              if (todaysClasses.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaysClasses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = todaysClasses[index];
                  return _buildClassTile(session);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 🎨 WIDGET: Attendance Overview
  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF303F9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4285F4).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  value: 0.78, // 78% Attendance
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                Text("78%", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Attendance Status", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text("You are Safe! 🛡️", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("2 more classes to reach 80%", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  // 🎨 WIDGET: Class Tile
  Widget _buildClassTile(ClassSession session) {
    final now = TimeOfDay.now();
    // Simple logic to check if class is active (visual only)
    final nowMin = now.hour * 60 + now.minute;
    final startMin = session.startTime.hour * 60 + session.startTime.minute;
    final endMin = session.endTime.hour * 60 + session.endTime.minute;
    final isActive = nowMin >= startMin && nowMin < endMin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: const Color(0xFF4285F4), width: 2) : null,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                "${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                "${session.endTime.hour}:${session.endTime.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 4, height: 40, color: session.isCancelled ? Colors.red : const Color(0xFF4285F4)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.subject, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(session.room, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.person, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(session.professor, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (session.isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text("CANCELLED", style: GoogleFonts.inter(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  // 🎨 WIDGET: Bus Tracker Teaser
  Widget _buildLiveBusCard() {
    return InkWell(
      onTap: () {
        // Navigate to /map or /bus
        // context.pushNamed('bus'); 
      },
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3E),
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Subtle pattern
            opacity: 0.1,
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFFB8C00), shape: BoxShape.circle),
              child: const Icon(Icons.directions_bus, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Live Bus Tracker", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Bus 4 is arriving at Campus Gate", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.weekend, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text("No Classes Today!", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Enjoy your free time.", style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red), 
        const SizedBox(width: 12), 
        Text(msg, style: const TextStyle(color: Colors.red))
      ]),
    );
  }
}