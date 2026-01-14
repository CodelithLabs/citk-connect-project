// lib/mail/models/extracted_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Structured data extracted from email body via AI
class ExtractedData {
  final List<DateTime> deadlines;
  final List<String> actionItems;
  final List<DateTime> importantDates;
  final List<String> mentionedProfessors;

  const ExtractedData({
    this.deadlines = const [],
    this.actionItems = const [],
    this.importantDates = const [],
    this.mentionedProfessors = const [],
  });

  /// Create from JSON (Firestore)
  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      deadlines: _parseDateList(json['deadlines']),
      actionItems: List<String>.from(json['action_items'] ?? []),
      importantDates: _parseDateList(json['important_dates']),
      mentionedProfessors: List<String>.from(json['mentioned_professors'] ?? []),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'deadlines': deadlines.map((d) => Timestamp.fromDate(d)).toList(),
      'action_items': actionItems,
      'important_dates': importantDates.map((d) => Timestamp.fromDate(d)).toList(),
      'mentioned_professors': mentionedProfessors,
    };
  }

  /// Helper to parse list of timestamps/dates
  static List<DateTime> _parseDateList(dynamic list) {
    if (list == null) return [];
    if (list is! List) return [];
    return list.map((item) {
      if (item is Timestamp) return item.toDate();
      if (item is String) return DateTime.tryParse(item) ?? DateTime.now();
      return DateTime.now();
    }).toList();
  }
  
  /// Empty state
  static const empty = ExtractedData();
}
