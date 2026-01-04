import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AspirantDashboard extends StatelessWidget {
  const AspirantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Future Student"),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text("Login"),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCard("Admission 2026", "Entrance exams (CITDEE) dates announced.", Icons.calendar_today, Colors.orange),
          _buildCard("Departments", "Explore CSE, ECE, Food Tech and more.", Icons.school, Colors.blue),
          _buildCard("Campus Tour", "Watch a drone view of the campus.", Icons.video_camera_back, Colors.red),
          _buildCard("Fee Structure", "Download the latest fee PDF.", Icons.attach_money, Colors.green),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}