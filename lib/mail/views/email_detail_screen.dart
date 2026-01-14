// lib/mail/views/email_detail_screen.dart

import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:citk_connect/mail/providers/mail_provider.dart';
import 'package:citk_connect/mail/views/widgets/ai_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmailDetailScreen extends ConsumerStatefulWidget {
  final CollegeEmail email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  ConsumerState<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends ConsumerState<EmailDetailScreen> {
  late final WebViewController _webViewController;
  bool _isLoadingWeb = true;

  @override
  void initState() {
    super.initState();

    // Mark as read if needed
    if (!widget.email.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mailProvider.notifier).markAsRead(widget.email.id);
      });
    }

    // Initialize WebView
    _initWebView();
  }

  void _initWebView() {
    final colorScheme =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? 'dark'
            : 'light';

    // Prepare HTML content with basic styling injection
    final String content = widget.email.fullBody ?? widget.email.bodySnippet;
    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: ${colorScheme == 'dark' ? '#E0E0E0' : '#333333'};
            background-color: ${colorScheme == 'dark' ? '#0F1115' : '#FFFFFF'};
            margin: 16px;
            word-wrap: break-word;
          }
          a { color: #1976D2; text-decoration: none; }
          img { max-width: 100%; height: auto; }
          pre { white-space: pre-wrap; background: ${colorScheme == 'dark' ? '#1E1E1E' : '#F5F5F5'}; padding: 10px; border-radius: 8px; }
        </style>
      </head>
      <body>
        $content
      </body>
      </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingWeb = false);
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('http')) {
              final uri = Uri.parse(request.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              // TODO: Implement archive
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Archive not implemented yet')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement delete
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Scrollable Header & AI Summary
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject & Category
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _CategoryChip(category: widget.email.category),
                                const Spacer(),
                                Text(
                                  DateFormat('MMM d, h:mm a')
                                      .format(widget.email.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.email.subject,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sender Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              radius: 20,
                              child: Text(
                                widget.email.from.name.isNotEmpty
                                    ? widget.email.from.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.email.from.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    widget.email.from.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Summary Widget
                      AiSummaryWidget(email: widget.email),

                      // Attachments Header (if any)
                      if (widget.email.hasAttachments)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.email.attachments.length} Attachments',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ],
              body: _isLoadingWeb
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _webViewController),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final EmailCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: category.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: category.color,
        ),
      ),
    );
  }
}
