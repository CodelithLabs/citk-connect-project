import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoticeEditorScreen extends StatelessWidget {
  const NoticeEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Notice Editor',
            style: GoogleFonts.robotoMono(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1115),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Create & Edit Notices',
            style: GoogleFonts.inter(color: Colors.white70)),
      ),
    );
  }
}
