import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PostUpdateScreen extends HookConsumerWidget {
  const PostUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final messageController = useTextEditingController();
    final isLoading = useState(false);
    final category = useState('General');

    Future<void> postUpdate() async {
      if (titleController.text.isEmpty || messageController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      isLoading.value = true;

      try {
        // 🚀 Write to Firestore
        // Note: A Cloud Function should listen to this collection and send FCM notifications to the 'updates' topic.
        await FirebaseFirestore.instance.collection('updates').add({
          'title': titleController.text.trim(),
          'message': messageController.text.trim(),
          'category': category.value,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update posted successfully!')),
          );
          context.pop(); // Go back after posting
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Post Update',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Title Field
            TextField(
              controller: titleController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title (e.g., EXAM ALERT)',
                labelStyle: GoogleFonts.inter(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF181B21),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF181B21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category.value,
                  dropdownColor: const Color(0xFF181B21),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: ['General', 'Exam', 'Event'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: GoogleFonts.inter(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) => category.value = newValue!,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message Field
            TextField(
              controller: messageController,
              style: GoogleFonts.inter(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.inter(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF181B21),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : postUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Broadcast Update',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
