// lib/mail/models/email_category.dart

import 'package:flutter/material.dart';

/// Categories for CITK emails based on AI analysis
enum EmailCategory {
  exam,
  fee,
  assignment,
  admin,
  event,
  general,
  spam,
  promotion;

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case EmailCategory.exam:
        return 'Exam';
      case EmailCategory.fee:
        return 'Fees';
      case EmailCategory.assignment:
        return 'Assignment';
      case EmailCategory.admin:
        return 'Admin';
      case EmailCategory.event:
        return 'Event';
      case EmailCategory.general:
        return 'General';
      case EmailCategory.spam:
        return 'Spam';
      case EmailCategory.promotion:
        return 'Promotion';
    }
  }

  /// Color coding for UI badges
  Color get color {
    switch (this) {
      case EmailCategory.exam:
        return Colors.redAccent;
      case EmailCategory.fee:
        return Colors.orange;
      case EmailCategory.assignment:
        return Colors.blue;
      case EmailCategory.admin:
        return Colors.purple;
      case EmailCategory.event:
        return Colors.green;
      case EmailCategory.general:
        return Colors.grey;
      case EmailCategory.spam:
        return Colors.brown;
      case EmailCategory.promotion:
        return Colors.teal;
    }
  }

  /// Parse from string (case-insensitive)
  static EmailCategory fromString(String? value) {
    if (value == null) return EmailCategory.general;
    try {
      return EmailCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return EmailCategory.general;
    }
  }
}
