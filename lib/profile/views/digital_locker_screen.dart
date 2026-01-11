import 'package:citk_connect/profile/services/document_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DigitalLockerScreen extends ConsumerWidget {
  const DigitalLockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Digital Locker', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.read(documentServiceProvider).getUserDocuments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading documents',
                    style: GoogleFonts.inter(color: Colors.red)));
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
                  Icon(Icons.folder_open_rounded,
                      size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No documents saved yet',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _DocumentCard(
                id: doc.id,
                data: data,
                isDark: isDark,
                onDelete: () => ref
                    .read(documentServiceProvider)
                    .deleteDocument(doc.id, data['fileName']),
              );
            },
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isDark;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.id,
    required this.data,
    required this.isDark,
    required this.onDelete,
  });

  Future<void> _openDocument() async {
    final url = Uri.parse(data['url']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Untitled';
    final type = data['type'] ?? 'DOC';
    final date = (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = "${date.day}/${date.month}/${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: _openDocument,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getFileColor(type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getFileIcon(type),
            color: _getFileColor(type),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$type • $dateStr',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Color _getFileColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'JPG':
      case 'PNG':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getFileIcon(String type) {
    return type.toUpperCase() == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.image_rounded;
  }
}