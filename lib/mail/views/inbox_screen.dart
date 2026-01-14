// lib/mail/views/inbox_screen.dart

import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:citk_connect/mail/providers/mail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Trigger initial sync after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mailProvider.notifier).syncEmails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mailState = ref.watch(mailProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'College Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Important'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Emails',
            onPressed: () {
              ref.read(mailProvider.notifier).syncEmails(fullSync: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Mail Settings',
            onPressed: () {
              context.push('/mail/settings');
            },
          ),
        ],
      ),
      body: mailState.when(
        data: (emails) {
          return TabBarView(
            controller: _tabController,
            children: [
              _EmailList(emails: emails),
              _EmailList(emails: emails.where((e) => !e.isRead).toList()),
              _EmailList(
                  emails: emails.where((e) => e.isHighPriority).toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load emails',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(mailProvider.notifier).syncEmails(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/mail/compose');
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _EmailList extends ConsumerWidget {
  final List<CollegeEmail> emails;

  const _EmailList({required this.emails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No emails found',
              style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(mailProvider.notifier).syncEmails(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: emails.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final email = emails[index];
          return Dismissible(
            key: Key(email.id),
            direction: !email.isRead
                ? DismissDirection.startToEnd
                : DismissDirection.none,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.mark_email_read, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await ref.read(mailProvider.notifier).markAsRead(email.id);
                return false; // Snap back and let provider rebuild list
              }
              return false;
            },
            child: _EmailListTile(email: email),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _EmailListTile extends StatelessWidget {
  final CollegeEmail email;

  const _EmailListTile({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !email.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/mail/details', extra: email);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      email.from.name,
                      style: GoogleFonts.inter(
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(email.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                email.subject,
                style: GoogleFonts.poppins(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                email.aiSummary ?? email.bodySnippet,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _CategoryBadge(category: email.category),
                  if (email.isHighPriority) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.priority_high,
                              size: 12, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Urgent',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (email.hasAttachments) ...[
                    const Spacer(),
                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final EmailCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: category.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category.displayName,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: category.color,
        ),
      ),
    );
  }
}
