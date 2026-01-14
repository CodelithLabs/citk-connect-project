// lib/mail/services/email_processor.dart

import 'dart:convert';

import 'package:citk_connect/ai/services/gemini_service.dart';
import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_category.dart';
import 'package:citk_connect/mail/models/extracted_data.dart';
import 'package:citk_connect/mail/services/priority_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;

/// Provider for the EmailProcessor service
final emailProcessorProvider = Provider<EmailProcessor>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  // PriorityEngine is a singleton
  return EmailProcessor(geminiService, PriorityEngine());
});

/// Service to process emails with AI and Priority Engine
class EmailProcessor {
  final GeminiService _geminiService;
  final PriorityEngine _priorityEngine;

  EmailProcessor(this._geminiService, this._priorityEngine);

  /// Process a single email: Analyze content, categorize, and score priority
  Future<CollegeEmail> processEmail(CollegeEmail email,
      {String? userId}) async {
    try {
      // 1. Extract clean text for AI analysis
      final cleanText = _extractCleanText(email);

      // 2. Analyze with Gemini
      // We use the subject and the cleaned body to save tokens and improve accuracy
      final aiResponse = await _geminiService.analyzeEmail(
        email.subject,
        cleanText,
        userId: userId,
      );

      // 3. Parse AI Response (JSON)
      final analysisMap = _parseAiJson(aiResponse.text);

      // 4. Map to Domain Models
      final category =
          EmailCategory.fromString(analysisMap['category'] as String?);
      final summary = analysisMap['summary'] as String?;

      final extractedData = ExtractedData(
        actionItems: List<String>.from(analysisMap['action_items'] ?? []),
        deadlines: _parseDates(analysisMap['deadlines']),
        // Note: importantDates and mentionedProfessors could be added to the prompt later
      );

      final geminiAnalysis = {
        'urgency_score': _parseUrgency(analysisMap['urgency']),
        'requires_action':
            (analysisMap['action_items'] as List?)?.isNotEmpty ?? false,
        'raw_response': aiResponse.text,
      };

      // 5. Create Enriched Email
      // We use the constructor because copyWith doesn't support updating geminiAnalysis map
      final enrichedEmail = CollegeEmail(
        id: email.id,
        messageId: email.messageId,
        subject: email.subject,
        from: email.from,
        bodySnippet: email.bodySnippet,
        fullBody: email.fullBody,
        timestamp: email.timestamp,
        priority: email.priority, // Will be updated in next step
        category: category,
        isRead: email.isRead,
        hasAttachments: email.hasAttachments,
        attachments: email.attachments,
        extractedData: extractedData,
        aiSummary: summary,
        tags: email.tags,
        geminiAnalysis: geminiAnalysis,
      );

      // 6. Calculate Priority
      final priority = _priorityEngine.calculatePriority(
        email: enrichedEmail,
        // userRules: [], // TODO: Fetch user rules from repository if needed
      );

      return enrichedEmail.copyWith(priority: priority);
    } catch (e) {
      debugPrint('Email Processing Failed for ${email.id}: $e');
      // Return original email on failure to ensure data isn't lost
      return email;
    }
  }

  /// Extract text from HTML body or use snippet if plain text
  String _extractCleanText(CollegeEmail email) {
    final text = email.fullBody ?? email.bodySnippet;
    // Simple check for HTML tags
    if (text.contains('<') && text.contains('>')) {
      try {
        final doc = html_parser.parse(text);
        return doc.body?.text.trim() ?? text;
      } catch (_) {
        return text;
      }
    }
    return text;
  }

  /// Parse JSON from AI response (handling potential markdown code blocks)
  Map<String, dynamic> _parseAiJson(String text) {
    try {
      var jsonString = text.trim();
      // Remove markdown code blocks if present (```json ... ```)
      if (jsonString.startsWith('```')) {
        final firstNewline = jsonString.indexOf('\n');
        final lastBackticks = jsonString.lastIndexOf('```');
        if (firstNewline != -1 && lastBackticks != -1) {
          jsonString = jsonString.substring(firstNewline, lastBackticks);
        }
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Parse Error: $e\nText: $text');
      return {};
    }
  }

  List<DateTime> _parseDates(dynamic dates) {
    if (dates is! List) return [];
    return dates
        .map((d) {
          return DateTime.tryParse(d.toString()) ?? DateTime.now();
        })
        .where((d) => d.year > 2000)
        .toList(); // Filter out invalid parses
  }

  int _parseUrgency(dynamic urgency) {
    if (urgency is num) return urgency.toInt();
    if (urgency is String) {
      // Map string urgency to numeric score (0-10 scale approximation)
      switch (urgency.toLowerCase()) {
        case 'high':
          return 8;
        case 'medium':
          return 5;
        case 'low':
          return 2;
        default:
          return 0;
      }
    }
    return 0;
  }
}
