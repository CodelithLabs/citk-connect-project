// lib/mail/services/gmail_sync_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_attachment.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

/// Service to synchronize emails from Gmail API securely
class GmailSyncService {
  // Singleton instance
  static final GmailSyncService _instance = GmailSyncService._internal();
  factory GmailSyncService() => _instance;
  GmailSyncService._internal();

  // Scopes must match AuthService to avoid re-consent issues
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.labels',
    ],
  );

  gmail.GmailApi? _gmailApi;

  /// Ensure API is initialized with an authenticated client
  Future<void> _ensureInitialized() async {
    if (_gmailApi != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in to sync emails');

    // Get the Google Sign-In account (silent sign-in if needed)
    var googleUser = _googleSignIn.currentUser;
    googleUser ??= await _googleSignIn.signInSilently();

    if (googleUser == null) {
      // If silent sign-in fails, we can't proceed without user interaction.
      // The UI should handle the initial sign-in flow via AuthService.
      throw Exception('Google Sign-In session expired. Please sign in again.');
    }

    // Get authenticated HTTP client securely
    // This extension method handles token refresh and secure headers
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Failed to authenticate with Google');
    }

    _gmailApi = gmail.GmailApi(client);
  }

  /// Fetch latest emails from Inbox
  /// [limit] - max number of emails to fetch
  /// [pageToken] - for pagination
  Future<List<CollegeEmail>> fetchInbox({
    int limit = 20,
    String? pageToken,
  }) async {
    await _ensureInitialized();

    try {
      // 1. List messages from Inbox
      final response = await _gmailApi!.users.messages.list(
        'me',
        maxResults: limit,
        pageToken: pageToken,
        q: 'in:inbox', // Filter for inbox only
      );

      if (response.messages == null || response.messages!.isEmpty) {
        return [];
      }

      // 2. Fetch full details for each message
      // We process in chunks to avoid overwhelming the network/API
      final List<CollegeEmail> emails = [];
      const int chunkSize = 5;

      for (var i = 0; i < response.messages!.length; i += chunkSize) {
        final end = (i + chunkSize < response.messages!.length)
            ? i + chunkSize
            : response.messages!.length;
        final chunk = response.messages!.sublist(i, end);

        final futures = chunk.map((msg) => _fetchEmailDetails(msg.id!));
        final results = await Future.wait(futures);
        emails.addAll(results.whereType<CollegeEmail>());
      }

      return emails;
    } catch (e) {
      debugPrint('Error fetching emails: $e');
      rethrow;
    }
  }

  /// Fetch full details of a single email
  Future<CollegeEmail?> _fetchEmailDetails(String messageId) async {
    try {
      final message = await _gmailApi!.users.messages.get(
        'me',
        messageId,
        format: 'full',
      );

      return _parseGmailMessage(message);
    } catch (e) {
      debugPrint('Failed to fetch message : ');
      return null;
    }
  }

  /// Parse Gmail API message to CollegeEmail model
  CollegeEmail _parseGmailMessage(gmail.Message message) {
    final payload = message.payload;
    if (payload == null) {
      throw FormatException('Message payload is null');
    }

    final headers = payload.headers ?? [];

    String getHeader(String name) {
      return headers
              .firstWhere(
                (h) => h.name?.toLowerCase() == name.toLowerCase(),
                orElse: () => gmail.MessagePartHeader(value: ''),
              )
              .value ??
          '';
    }

    final subject = getHeader('Subject');
    final fromRaw = getHeader('From');

    // Internal Date is epoch ms
    final timestamp = message.internalDate != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(message.internalDate!))
        : DateTime.now();

    // Body extraction (Prioritize HTML, fallback to Text)
    String bodySnippet = message.snippet ?? '';
    String? fullBody = _extractBody(payload, 'text/html') ??
        _extractBody(payload, 'text/plain');

    // Attachments
    final attachments = _extractAttachments(payload, message.id!);

    // Read status
    final labelIds = message.labelIds ?? [];
    final isRead = !labelIds.contains('UNREAD');

    return CollegeEmail(
      id: message.id!, // Use message ID as temporary doc ID
      messageId: message.id!,
      subject: subject.isEmpty ? '(No Subject)' : subject,
      from: EmailAddress.parse(fromRaw),
      bodySnippet: bodySnippet,
      fullBody: fullBody,
      timestamp: timestamp,
      priority: 1, // Default, calculated later by PriorityEngine
      category: EmailCategory.general, // Default, calculated later by AI
      isRead: isRead,
      hasAttachments: attachments.isNotEmpty,
      attachments: attachments,
    );
  }

  /// Recursively extract body text/html
  String? _extractBody(gmail.MessagePart part, String mimeType) {
    if (part.mimeType == mimeType && part.body?.data != null) {
      return utf8.decode(base64Url.decode(part.body!.data!));
    }

    if (part.parts != null) {
      for (final subPart in part.parts!) {
        final body = _extractBody(subPart, mimeType);
        if (body != null) return body;
      }
    }
    return null;
  }

  /// Extract attachment metadata
  List<EmailAttachment> _extractAttachments(
      gmail.MessagePart part, String messageId) {
    final List<EmailAttachment> attachments = [];

    if (part.filename != null && part.filename!.isNotEmpty) {
      attachments.add(EmailAttachment(
        name: part.filename!,
        mimeType: part.mimeType ?? 'application/octet-stream',
        sizeBytes: part.body?.size ?? 0,
        attachmentId: part.body?.attachmentId,
      ));
    }

    if (part.parts != null) {
      for (final subPart in part.parts!) {
        attachments.addAll(_extractAttachments(subPart, messageId));
      }
    }

    return attachments;
  }

  /// Download attachment content securely
  Future<Uint8List?> downloadAttachment(
      String messageId, String attachmentId) async {
    await _ensureInitialized();
    try {
      final part = await _gmailApi!.users.messages.attachments.get(
        'me',
        messageId,
        attachmentId,
      );

      if (part.data != null) {
        return base64Url.decode(part.data!);
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading attachment: ');
      return null;
    }
  }

  /// Mark email as read/unread
  Future<void> modifyLabels(String messageId,
      {List<String>? add, List<String>? remove}) async {
    await _ensureInitialized();
    try {
      final request = gmail.BatchModifyMessagesRequest(
        ids: [messageId],
        addLabelIds: add,
        removeLabelIds: remove,
      );

      await _gmailApi!.users.messages.batchModify(request, 'me');
    } catch (e) {
      debugPrint('Error modifying labels: ');
      rethrow;
    }
  }

  /// Send an email
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    await _ensureInitialized();
    try {
      final message = gmail.Message();

      final String rawString = 'To: $to\r\n'
          'Subject: $subject\r\n'
          'Content-Type: text/plain; charset="UTF-8"\r\n\r\n'
          '$body';

      final List<int> bytes = utf8.encode(rawString);
      final String base64Email = base64Url.encode(bytes);

      message.raw = base64Email;

      await _gmailApi!.users.messages.send(message, 'me');
    } catch (e) {
      debugPrint('Error sending email: $e');
      rethrow;
    }
  }
}
