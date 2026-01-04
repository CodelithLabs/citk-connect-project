import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Import Firestore

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Deep background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Notices & Events",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 📢 1. LIVE NOTICES STREAM
          Text("Pinned Updates",
              style: GoogleFonts.inter(
                  color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notices').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Error loading notices", style: TextStyle(color: Colors.red));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text("No new updates.", style: TextStyle(color: Colors.grey));

              // Convert Firestore Docs to Widgets
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildNoticeCard(
                    title: data['title'] ?? 'Untitled',
                    date: data['date'] ?? 'Just now',
                    type: data['type'] ?? 'INFO',
                    // Logic to pick color based on type
                    color: (data['type'] == 'URGENT') ? Colors.redAccent : Colors.orangeAccent,
                    icon: (data['type'] == 'URGENT') ? Icons.priority_high : Icons.info_outline,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // 🎉 2. LIVE EVENTS STREAM
          Text("Upcoming Events",
              style: GoogleFonts.inter(
                  color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').orderBy('date_sort', descending: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SizedBox(); // Hide if error
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text("No upcoming events.", style: TextStyle(color: Colors.grey));

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildEventCard(
                    title: data['title'] ?? 'New Event',
                    date: data['date_display'] ?? 'TBA',
                    location: data['location'] ?? 'Campus',
                    // Random-ish color assignment or stored in DB
                    imageColor: _getColorFromHex(data['color_hex']), 
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper to handle color strings
  Color _getColorFromHex(String? hex) {
    if (hex == null) return Colors.blueAccent;
    if (hex == 'purple') return Colors.purpleAccent;
    if (hex == 'pink') return Colors.pinkAccent;
    if (hex == 'orange') return Colors.orangeAccent;
    return Colors.blueAccent;
  }

  // Widget for Urgent Notices
  Widget _buildNoticeCard(
      {required String title,
      required String date,
      required String type,
      required Color color,
      required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181B21), // Card Background
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(type,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(date,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  // Widget for Events
  Widget _buildEventCard(
      {required String title,
      required String date,
      required String location,
      required Color imageColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake Event Image Area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [imageColor.withValues(alpha: 0.4), imageColor.withValues(alpha: 0.1)]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.event_available, size: 50, color: imageColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date, style: GoogleFonts.inter(color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location,
                        style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}