// lib/mail/providers/mail_provider.dart

import 'dart:async';

import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:citk_connect/mail/services/email_processor.dart';
import 'package:citk_connect/mail/services/gmail_sync_service.dart';
import 'package:citk_connect/mail/services/mail_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// -----------------------------------------------------------------------------
// 📦 DEPENDENCY PROVIDERS
// -----------------------------------------------------------------------------

final mailRepositoryProvider = Provider<MailRepository>((ref) {
  return MailRepository();
});

final gmailSyncServiceProvider = Provider<GmailSyncService>((ref) {
  return GmailSyncService();
});

// -----------------------------------------------------------------------------
// 📧 MAIL STATE PROVIDER
// -----------------------------------------------------------------------------

/// Manages the list of emails and synchronization state
final mailProvider =
    AsyncNotifierProvider<MailNotifier, List<CollegeEmail>>(MailNotifier.new);

class MailNotifier extends AsyncNotifier<List<CollegeEmail>> {
  late final MailRepository _repository;
  late final GmailSyncService _gmailService;
  late final EmailProcessor _processor;

  @override
  Future<List<CollegeEmail>> build() async {
    _repository = ref.watch(mailRepositoryProvider);
    _gmailService = ref.watch(gmailSyncServiceProvider);
    _processor = ref.watch(emailProcessorProvider);

    final user = ref.watch(authServiceProvider).value;
    if (user == null) return [];

    // Load cached emails from Firestore initially
    // We fetch all available cached emails sorted by priority
    return _repository.getEmailsByPriority(user.uid, 0);
  }

  /// Synchronize emails from Gmail, process with AI, and update state
  Future<void> syncEmails({bool fullSync = false}) async {
    final user = ref.read(authServiceProvider).value;
    if (user == null) return;

    // Don't set state to loading to avoid UI flicker, just background update
    // unless it's the first load and list is empty.
    if (state.valueOrNull?.isEmpty ?? true) {
      state = const AsyncValue.loading();
    }

    try {
      // 1. Fetch from Gmail
      final rawEmails =
          await _gmailService.fetchInbox(limit: fullSync ? 50 : 20);

      if (rawEmails.isEmpty) {
        if (state.valueOrNull?.isEmpty ?? true) {
          state = const AsyncValue.data([]);
        }
        return;
      }

      // 2. Process & Save (Batch/Parallel)
      final List<CollegeEmail> processedEmails = [];

      for (final email in rawEmails) {
        // Check if we already have this email and it's processed
        final existing = state.valueOrNull?.firstWhere(
          (e) => e.messageId == email.messageId,
          orElse: () => email, // Placeholder
        );

        // If existing has AI data, skip re-processing unless forced
        if (existing != null &&
            existing.id == email.messageId &&
            existing.geminiAnalysis.isNotEmpty) {
          processedEmails.add(existing);
          continue;
        }

        // Process with AI
        final processed =
            await _processor.processEmail(email, userId: user.uid);

        // Save to Firestore
        await _repository.saveEmail(user.uid, processed);
        processedEmails.add(processed);
      }

      // 3. Merge with current state
      final currentList = state.valueOrNull ?? [];
      final Map<String, CollegeEmail> emailMap = {
        for (var e in currentList) e.messageId: e
      };

      for (var e in processedEmails) {
        emailMap[e.messageId] = e;
      }

      final newList = emailMap.values.toList()
        ..sort((a, b) {
          // Sort by Priority (desc), then Timestamp (desc)
          final priorityComp = b.priority.compareTo(a.priority);
          if (priorityComp != 0) return priorityComp;
          return b.timestamp.compareTo(a.timestamp);
        });

      state = AsyncValue.data(newList);
    } catch (e, st) {
      debugPrint('Sync failed: $e');
      // Keep old data if sync fails, but maybe show snackbar via a side-effect provider
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Mark email as read
  Future<void> markAsRead(String emailId) async {
    final user = ref.read(authServiceProvider).value;
    if (user == null) return;

    // Optimistic update
    final currentList = state.valueOrNull ?? [];
    final index = currentList.indexWhere((e) => e.id == emailId);
    if (index == -1) return;

    final updatedEmail = currentList[index].copyWith(isRead: true);
    currentList[index] = updatedEmail;
    state = AsyncValue.data([...currentList]);

    try {
      await _repository.markAsRead(user.uid, emailId);
      // Sync with Gmail API to mark as read on server
      await _gmailService
          .modifyLabels(updatedEmail.messageId, remove: ['UNREAD']);
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }
}

// -----------------------------------------------------------------------------
// 🔍 FILTER PROVIDERS
// -----------------------------------------------------------------------------

final unreadEmailsProvider = Provider<List<CollegeEmail>>((ref) {
  final emails = ref.watch(mailProvider).valueOrNull ?? [];
  return emails.where((e) => !e.isRead).toList();
});

final highPriorityEmailsProvider = Provider<List<CollegeEmail>>((ref) {
  final emails = ref.watch(mailProvider).valueOrNull ?? [];
  return emails.where((e) => e.isHighPriority).toList();
});

final categoryEmailsProvider =
    Provider.family<List<CollegeEmail>, EmailCategory>((ref, category) {
  final emails = ref.watch(mailProvider).valueOrNull ?? [];
  return emails.where((e) => e.category == category).toList();
});
