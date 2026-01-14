import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusManagementScreen extends StatelessWidget {
  const BusManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Bus Management',
            style: GoogleFonts.robotoMono(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1115),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Bus Management Console',
            style: GoogleFonts.inter(color: Colors.white70)),
      ),
    );
  }
}
