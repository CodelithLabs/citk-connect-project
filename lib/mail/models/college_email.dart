// lib/mail/models/college_email.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:citk_connect/mail/models/email_attachment.dart';
import 'package:citk_connect/mail/models/extracted_data.dart';

/// Represents a sender's email address and name
class EmailAddress {
  final String name;
  final String email;

  const EmailAddress({required this.name, required this.email});

  factory EmailAddress.fromJson(Map<String, dynamic> json) {
    return EmailAddress(
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
    );
  }
  
  factory EmailAddress.parse(String raw) {
    // Parses "Name <email@domain.com>" or just "email@domain.com"
    final RegExp regex = RegExp(r'(.*)<(.*)>');
    final match = regex.firstMatch(raw);
    if (match != null) {
      return EmailAddress(
        name: match.group(1)?.trim().replaceAll('"', '') ?? 'Unknown',
        email: match.group(2)?.trim() ?? '',
      );
    }
    return EmailAddress(name: raw.split('@').first, email: raw);
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
  
  @override
  String toString() => '$name <>';
}

/// Primary Data Model for the Email Intelligence System
class CollegeEmail {
  final String id; // Firestore Document ID
  final String messageId; // Gmail Message ID
  final String subject;
  final EmailAddress from;
  final String bodySnippet;
  final String? fullBody;
  final DateTime timestamp;
  final int priority; // 1-10
  final EmailCategory category;
  final bool isRead;
  final bool hasAttachments;
  final List<EmailAttachment> attachments;
  final ExtractedData extractedData;
  final String? aiSummary;
  final List<String> tags;
  final Map<String, dynamic> geminiAnalysis;

  const CollegeEmail({
    required this.id,
    required this.messageId,
    required this.subject,
    required this.from,
    required this.bodySnippet,
    this.fullBody,
    required this.timestamp,
    this.priority = 1,
    this.category = EmailCategory.general,
    this.isRead = false,
    this.hasAttachments = false,
    this.attachments = const [],
    this.extractedData = ExtractedData.empty,
    this.aiSummary,
    this.tags = const [],
    this.geminiAnalysis = const {},
  });

  // ---------------------------------------------------------------------------
  // 🏭 FACTORIES
  // ---------------------------------------------------------------------------

  /// Create from Firestore Document
  factory CollegeEmail.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollegeEmail.fromJson(data, doc.id);
  }

  /// Create from JSON map
  factory CollegeEmail.fromJson(Map<String, dynamic> json, [String? docId]) {
    return CollegeEmail(
      id: docId ?? json['id'] ?? '',
      messageId: json['message_id'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      from: json['from'] is Map 
          ? EmailAddress.fromJson(json['from']) 
          : EmailAddress.parse(json['from'] ?? 'Unknown'),
      bodySnippet: json['body_snippet'] ?? '',
      fullBody: json['full_body'],
      timestamp: _parseTimestamp(json['timestamp']),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      category: EmailCategory.fromString(json['category']),
      isRead: json['read_status'] ?? false,
      hasAttachments: json['has_attachments'] ?? false,
      attachments: (json['attachments'] as List?)
              ?.map((e) => EmailAttachment.fromJson(e))
              .toList() ??
          [],
      extractedData: json['extracted_data'] != null
          ? ExtractedData.fromJson(json['extracted_data'])
          : ExtractedData.empty,
      aiSummary: json['ai_summary'],
      tags: List<String>.from(json['tags'] ?? []),
      geminiAnalysis: json['gemini_analysis'] ?? {},
    );
  }

  // ---------------------------------------------------------------------------
  // 💾 SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'subject': subject,
      'from': from.toJson(),
      'body_snippet': bodySnippet,
      'full_body': fullBody,
      'timestamp': Timestamp.fromDate(timestamp),
      'priority': priority,
      'category': category.name,
      'read_status': isRead,
      'has_attachments': hasAttachments,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'extracted_data': extractedData.toJson(),
      'ai_summary': aiSummary,
      'tags': tags,
      'gemini_analysis': geminiAnalysis,
    };
  }

  // ---------------------------------------------------------------------------
  // 🧮 COMPUTED PROPERTIES
  // ---------------------------------------------------------------------------

  bool get isHighPriority => priority >= 7;
  
  bool get hasDeadlines => extractedData.deadlines.isNotEmpty;
  
  bool get requiresAction => 
      geminiAnalysis['requires_action'] == true || 
      extractedData.actionItems.isNotEmpty;

  // ---------------------------------------------------------------------------
  // 🛠️ UTILITIES
  // ---------------------------------------------------------------------------

  CollegeEmail copyWith({
    String? subject,
    bool? isRead,
    int? priority,
    EmailCategory? category,
    String? aiSummary,
    ExtractedData? extractedData,
  }) {
    return CollegeEmail(
      id: id,
      messageId: messageId,
      subject: subject ?? this.subject,
      from: from,
      bodySnippet: bodySnippet,
      fullBody: fullBody,
      timestamp: timestamp,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments,
      attachments: attachments,
      extractedData: extractedData ?? this.extractedData,
      aiSummary: aiSummary ?? this.aiSummary,
      tags: tags,
      geminiAnalysis: geminiAnalysis,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  @override
  String toString() => 'CollegeEmail(id: , subject: , priority: )';
}
