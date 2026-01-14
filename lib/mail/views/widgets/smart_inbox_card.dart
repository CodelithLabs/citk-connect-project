// lib/mail/views/widgets/smart_inbox_card.dart

import 'package:citk_connect/mail/providers/mail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartInboxCard extends ConsumerWidget {
  const SmartInboxCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch specific providers for optimized rebuilds
    final unreadCount = ref.watch(unreadEmailsProvider).length;
    final highPriorityCount = ref.watch(highPriorityEmailsProvider).length;
    final mailState = ref.watch(mailProvider);

    // Define gradients based on theme
    final gradientColors = isDark
        ? [const Color(0xFF2D3561), const Color(0xFF1A1F3A)]
        : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];

    return GestureDetector(
      onTap: () => context.push('/inbox'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                Icons.mail_rounded,
                color: isDark ? Colors.white : const Color(0xFF1976D2),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'College Inbox',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  mailState.when(
                    data: (_) {
                      if (unreadCount == 0) {
                        return Text(
                          'All caught up! 🎉',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            '$unreadCount unread',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          if (highPriorityCount > 0) ...[
                            const SizedBox(width: 8),
                            _UrgentBadge(count: highPriorityCount),
                          ],
                        ],
                      );
                    },
                    loading: () => Text(
                      'Syncing...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Sync failed',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  final int count;

  const _UrgentBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.priority_high_rounded,
            size: 10,
            color: Color(0xFFD32F2F),
          ),
          const SizedBox(width: 2),
          Text(
            '$count Urgent',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(duration: 1000.ms, begin: 0.8, end: 1.0);
  }
}
