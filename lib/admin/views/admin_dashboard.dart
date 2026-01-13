import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:citk_connect/ai/services/gemini_service.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const kBg = Color(0xFF0F1115);
    const kCard = Color(0xFF181B21);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("AI BRAIN MONITOR",
            style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kBg,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ai_feedback')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Error loading logs",
                    style: GoogleFonts.inter(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology_alt,
                      size: 60, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text("No feedback yet.",
                      style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isHelpful = data['isHelpful'] == true;
              final query = data['query'] ?? "Unknown";
              final response = data['response'] ?? "No response";
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHelpful
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHelpful
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      isHelpful ? "🔥" : "💩",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                      ),
                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}",
                            style: GoogleFonts.robotoMono(
                                color: Colors.white24, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white24),
                    onPressed: () => _confirmDelete(context, docs[index].id),
                  ),
                  onTap: () => _showDetailDialog(context, query, response),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B21),
        title:
            Text("Delete Log?", style: GoogleFonts.inter(color: Colors.white)),
        content: Text("This action cannot be undone.",
            style: GoogleFonts.inter(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('ai_feedback').doc(docId).delete();
            },
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, String query, String response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B21),
        title:
            Text("Log Details", style: GoogleFonts.inter(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("USER ASKED:",
                  style: GoogleFonts.robotoMono(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(query, style: GoogleFonts.inter(color: Colors.white)),
              const SizedBox(height: 16),
              Text("AI REPLIED:",
                  style: GoogleFonts.robotoMono(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(response, style: GoogleFonts.inter(color: Colors.grey[300])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(context: context, builder: (_) => _TestAiDialog(initialQuery: query));
            },
            child: Text("Retry / Test", style: GoogleFonts.inter(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.inter(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _TestAiDialog extends ConsumerStatefulWidget {
  final String initialQuery;
  const _TestAiDialog({required this.initialQuery});

  @override
  ConsumerState<_TestAiDialog> createState() => _TestAiDialogState();
}

class _TestAiDialogState extends ConsumerState<_TestAiDialog> {
  late TextEditingController _controller;
  String? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    setState(() => _isLoading = true);
    final response = await ref.read(geminiServiceProvider).sendMessage(_controller.text);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = response.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181B21),
      title: Text("Test AI Logic", style: GoogleFonts.inter(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Prompt",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI RESPONSE:", style: GoogleFonts.robotoMono(color: Colors.greenAccent, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(_result!, style: GoogleFonts.inter(color: Colors.white70)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _runTest,
          child: Text("Run", style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close", style: GoogleFonts.inter(color: Colors.grey)),
        ),
      ],
    );
  }
}
