import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.value;
    final theme = Theme.of(context);

    // 🛡️ SAFE NAME LOGIC
    // If name is null OR empty, use "Student".
    final String safeName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : "Student";
    
    // Get first letter safely
    final String firstLetter = safeName.isNotEmpty ? safeName[0].toUpperCase() : "S";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CITK Connect",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No new notifications")));
            },
          ),
          // 3-Dot Menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                // Router redirects automatically
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('My Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Log Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              accountName: Text(
                safeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? "No Email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                    ? Text(firstLetter, style: const TextStyle(fontSize: 24, color: Colors.white))
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.blueAccent),
              title: const Text('My Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                context.pop();
                await ref.read(authServiceProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good Morning,", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                  Text(
                    safeName.split(' ')[0],
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ).animate().fadeIn().moveX(begin: -20, end: 0),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text("Find hostels, labs, or seniors...",
                            style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildFeatureCard(
                  context,
                  title: "Campus Map",
                  icon: Icons.map_outlined,
                  color: Colors.blueAccent,
                  desc: "Navigate CITK in 3D",
                  onTap: () => context.push('/map'),
                ),
                _buildFeatureCard(
                  context,
                  title: "Academics",
                  icon: Icons.school_outlined,
                  color: Colors.orangeAccent,
                  desc: "Routine & PYQ",
                  onTap: () => context.push('/routine'),
                ),
                _buildFeatureCard(
                  context,
                  title: "Bus Tracker",
                  icon: Icons.directions_bus_outlined,
                  color: Colors.greenAccent,
                  desc: "Live Status",
                  onTap: () => context.push('/bus'),
                ),
                _buildFeatureCard(
                  context,
                  title: "AI Assistant",
                  icon: Icons.auto_awesome_outlined,
                  color: Colors.purpleAccent,
                  desc: "Ask anything",
                  onTap: () => context.push('/ai'),
                ),
                _buildFeatureCard(
                  context,
                  title: "Events",
                  icon: Icons.calendar_month_outlined,
                  color: Colors.pinkAccent,
                  desc: "Tech Fest & more",
                  onTap: () => context.push('/events'),
                ),
                // Emergency (Uncomment if route exists)
                // _buildFeatureCard(
                //   context,
                //   title: "Emergency",
                //   icon: Icons.local_hospital_outlined,
                //   color: Colors.redAccent,
                //   desc: "Medical & Security",
                //   onTap: () => context.push('/emergency'),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}