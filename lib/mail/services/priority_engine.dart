// lib/mail/services/priority_engine.dart

import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/models/email_category.dart';

/// Represents a user-defined rule for prioritizing emails
class PriorityRule {
  final String id;
  final String? sender;
  final List<String> keywords;
  final int priorityScore; // Can be positive or negative

  const PriorityRule({
    required this.id,
    this.sender,
    this.keywords = const [],
    required this.priorityScore,
  });

  factory PriorityRule.fromJson(Map<String, dynamic> json) {
    return PriorityRule(
      id: json['id'] ?? '',
      sender: json['sender'],
      keywords: List<String>.from(json['keywords'] ?? []),
      priorityScore: json['priority_score'] ?? 0,
    );
  }
}

/// Service to calculate email priority scores (1-10)
class PriorityEngine {
  static final PriorityEngine _instance = PriorityEngine._internal();
  factory PriorityEngine() => _instance;
  PriorityEngine._internal();

  /// Calculate priority score based on system rules, AI analysis, and user rules
  int calculatePriority({
    required CollegeEmail email,
    List<PriorityRule> userRules = const [],
  }) {
    double score = 1.0; // Base score

    final sender = email.from.email.toLowerCase();
    final subject = email.subject.toLowerCase();
    final body = email.bodySnippet.toLowerCase();

    // -------------------------------------------------------------------------
    // 1. SYSTEM RULES (Domain Specific)
    // -------------------------------------------------------------------------

    // High Authority Senders
    if (sender.contains('exam') || sender.contains('controller'))
      score += 9;
    else if (sender.contains('director') || sender.contains('registrar'))
      score += 8;
    else if (sender.contains('hod'))
      score += 7;
    else if (sender.contains('accounts') || sender.contains('finance'))
      score += 6;
    else if (sender.contains('tpo') || sender.contains('placement'))
      score += 6;
    else if (sender.contains('library'))
      score += 4;
    else if (sender.endsWith('@cit.ac.in')) score += 2; // Internal domain boost

    // Keywords in Subject
    if (subject.contains('urgent') || subject.contains('immediate')) score += 4;
    if (subject.contains('deadline') || subject.contains('due')) score += 3;
    if (subject.contains('schedule') || subject.contains('routine')) score += 3;
    if (subject.contains('notice') || subject.contains('circular')) score += 2;
    if (subject.contains('result') || subject.contains('grade')) score += 5;

    // -------------------------------------------------------------------------
    // 2. CATEGORY WEIGHTS
    // -------------------------------------------------------------------------
    switch (email.category) {
      case EmailCategory.exam:
        score += 4;
        break;
      case EmailCategory.fee:
        score += 3;
        break;
      case EmailCategory.assignment:
        score += 3;
        break;
      case EmailCategory.admin:
        score += 2;
        break;
      case EmailCategory.event:
        score += 1;
        break;
      case EmailCategory.spam:
      case EmailCategory.promotion:
        score -= 5;
        break;
      default:
        break;
    }

    // -------------------------------------------------------------------------
    // 3. AI ANALYSIS SIGNALS
    // -------------------------------------------------------------------------
    if (email.geminiAnalysis.isNotEmpty) {
      // Urgency from AI (0-10 scale usually, normalize to boost)
      final aiUrgency =
          (email.geminiAnalysis['urgency_score'] as num?)?.toDouble() ?? 0;
      score += (aiUrgency * 0.5); // Add half of AI urgency score

      if (email.geminiAnalysis['requires_action'] == true) {
        score += 2;
      }
    }

    // -------------------------------------------------------------------------
    // 4. USER CUSTOM RULES
    // -------------------------------------------------------------------------
    for (final rule in userRules) {
      bool matched = false;

      // Check Sender
      if (rule.sender != null && rule.sender!.isNotEmpty) {
        if (sender.contains(rule.sender!.toLowerCase())) {
          matched = true;
        }
      }

      // Check Keywords
      if (!matched && rule.keywords.isNotEmpty) {
        for (final keyword in rule.keywords) {
          if (subject.contains(keyword.toLowerCase()) ||
              body.contains(keyword.toLowerCase())) {
            matched = true;
            break;
          }
        }
      }

      if (matched) {
        score += rule.priorityScore;
      }
    }

    return score.round().clamp(1, 10);
  }
}
