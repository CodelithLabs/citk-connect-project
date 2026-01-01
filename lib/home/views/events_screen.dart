import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notices & Events", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. PINNED / URGENT NOTICES
          Text("Pinned Updates", style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildNoticeCard(
            title: "End-Term Exam Schedule Released",
            date: "Today, 10:00 AM",
            type: "ACADEMIC",
            color: Colors.redAccent,
            icon: Icons.priority_high,
          ),
          _buildNoticeCard(
            title: "Bus Service Suspended on Sunday",
            date: "Yesterday",
            type: "ADMIN",
            color: Colors.orangeAccent,
            icon: Icons.warning_amber,
          ),

          const SizedBox(height: 24),

          // 2. UPCOMING EVENTS
          Text("Upcoming Events", style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildEventCard(
            title: "TechX 2025 Hackathon",
            date: "Jan 20 - Jan 22",
            location: "Central IT Lab",
            imageColor: Colors.purpleAccent,
          ),
          _buildEventCard(
            title: "Freshers' Welcome Party",
            date: "Feb 14, 5:00 PM",
            location: "Main Auditorium",
            imageColor: Colors.pinkAccent,
          ),
           _buildEventCard(
            title: "Robotics Workshop",
            date: "Feb 20, 10:00 AM",
            location: "ECE Seminar Hall",
            imageColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  // Widget for Urgent Notices
  Widget _buildNoticeCard({required String title, required String date, required String type, required Color color, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color..withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      child: Text(type, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  // Widget for Events with "Images" (Placeholders)
  Widget _buildEventCard({required String title, required String date, required String location, required Color imageColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake Event Image Area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: imageColor..withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.event, size: 50, color: imageColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date, style: GoogleFonts.inter(color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: GoogleFonts.inter(color: Colors.grey)),
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