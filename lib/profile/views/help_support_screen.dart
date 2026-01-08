import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends HookConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feedbackController = useTextEditingController();
    final isSubmitting = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(context, 'How do I track the bus?',
                'Go to the "Bus" tab in the bottom navigation bar to see live location and ETA.'),
            _buildFAQItem(context, 'Who can I contact for hostel issues?',
                'You can contact the Chief Warden via the contact details provided below.'),
            _buildFAQItem(context, 'Is the AI Assistant accurate?',
                'The AI is trained on general campus data. For critical academic info, please verify with the department.'),
            _buildFAQItem(context, 'How do I reset my password?',
                'Currently, password reset is handled by the IT cell. Please email support.'),
            const SizedBox(height: 32),
            Text(
              'Contact Us',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactTile(context, Icons.email_outlined, 'Email Support',
                'helpdesk@cit.ac.in', 'mailto:helpdesk@cit.ac.in'),
            _buildContactTile(context, Icons.phone_outlined, 'Emergency',
                '+91 12345 67890', 'tel:+911234567890'),
            _buildContactTile(context, Icons.language, 'Website',
                'www.cit.ac.in', 'https://cit.ac.in'),
            const SizedBox(height: 32),
            Text(
              'Send Feedback',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              style: GoogleFonts.inter(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Tell us how we can improve...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting.value
                    ? null
                    : () async {
                        if (feedbackController.text.trim().isEmpty) return;
                        isSubmitting.value = true;
                        try {
                          await FirebaseFirestore.instance
                              .collection('feedback')
                              .add({
                            'message': feedbackController.text.trim(),
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            feedbackController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Thank you for your feedback!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          isSubmitting.value = false;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Submit Feedback',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: Colors.grey,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, IconData icon, String title,
      String subtitle, String url) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_outward, size: 16, color: Colors.grey),
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            // Handle error
          }
        },
      ),
    );
  }
}
