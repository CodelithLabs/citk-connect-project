import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DriverAlertsScreen extends ConsumerWidget {
  const DriverAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          'FLEET ALERTS',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('driver_alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading alerts',
                  style: GoogleFonts.inter(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    "All Systems Nominal",
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _AlertCard(data: data, docId: docId);
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _AlertCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final bool isResolved = data['resolved'] ?? false;
    final Timestamp? ts = data['timestamp'];
    final DateTime date = ts?.toDate() ?? DateTime.now();
    final String timeStr = DateFormat('hh:mm a • dd MMM').format(date);
    final double speed = (data['speed_kmph'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved ? Colors.white10 : const Color(0xFFFF5252),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isResolved
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFFF5252).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isResolved ? Icons.check : Icons.speed_rounded,
            color: isResolved ? Colors.grey : const Color(0xFFFF5252),
          ),
        ),
        title: Row(
          children: [
            Text(
              "BUS ${data['busId'].toString().replaceAll('bus_', '')}",
              style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (!isResolved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "OVERSPEED",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${speed.toStringAsFixed(1)} km/h detected",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            Text(
              timeStr,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        trailing: isResolved
            ? null
            : IconButton(
                icon:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => FirebaseFirestore.instance
                    .collection('driver_alerts')
                    .doc(docId)
                    .update({'resolved': true}),
              ),
      ),
    ).animate().fadeIn().slideX();
  }
}
