// lib/mail/services/mail_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:citk_connect/mail/models/college_email.dart';
import 'package:citk_connect/mail/services/priority_engine.dart';

/// Settings for mail synchronization and notifications
class MailSettings {
  final bool enabled;
  final int syncIntervalMin;
  final bool notifyHighPriorityOnly;
  final bool firstSyncCompleted;
  final DateTime? lastSyncTimestamp;

  const MailSettings({
    this.enabled = true,
    this.syncIntervalMin = 15,
    this.notifyHighPriorityOnly = false,
    this.firstSyncCompleted = false,
    this.lastSyncTimestamp,
  });

  factory MailSettings.fromMap(Map<String, dynamic> map) {
    return MailSettings(
      enabled: map['enabled'] ?? true,
      syncIntervalMin: map['sync_interval_min'] ?? 15,
      notifyHighPriorityOnly: map['notify_high_priority_only'] ?? false,
      firstSyncCompleted: map['first_sync_completed'] ?? false,
      lastSyncTimestamp: (map['last_sync_timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sync_interval_min': syncIntervalMin,
      'notify_high_priority_only': notifyHighPriorityOnly,
      'first_sync_completed': firstSyncCompleted,
      'last_sync_timestamp': lastSyncTimestamp != null
          ? Timestamp.fromDate(lastSyncTimestamp!)
          : null,
    };
  }

  MailSettings copyWith({
    bool? enabled,
    int? syncIntervalMin,
    bool? notifyHighPriorityOnly,
    bool? firstSyncCompleted,
    DateTime? lastSyncTimestamp,
  }) {
    return MailSettings(
      enabled: enabled ?? this.enabled,
      syncIntervalMin: syncIntervalMin ?? this.syncIntervalMin,
      notifyHighPriorityOnly:
          notifyHighPriorityOnly ?? this.notifyHighPriorityOnly,
      firstSyncCompleted: firstSyncCompleted ?? this.firstSyncCompleted,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
    );
  }
}

class MailRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 📧 EMAIL OPERATIONS
  // ---------------------------------------------------------------------------

  /// Save or update an email in Firestore
  Future<void> saveEmail(String userId, CollegeEmail email) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .doc(email.id)
        .set(email.toJson(), SetOptions(merge: true));
  }

  /// Get a single email by ID
  Future<CollegeEmail?> getEmail(String userId, String emailId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .doc(emailId)
        .get();

    if (doc.exists) {
      return CollegeEmail.fromFirestore(doc);
    }
    return null;
  }

  /// Get emails filtered by minimum priority
  Future<List<CollegeEmail>> getEmailsByPriority(
      String userId, int minPriority) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .where('priority', isGreaterThanOrEqualTo: minPriority)
        .orderBy('priority', descending: true)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => CollegeEmail.fromFirestore(doc)).toList();
  }

  /// Watch unread emails stream
  Stream<List<CollegeEmail>> watchUnreadEmails(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .where('read_status', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollegeEmail.fromFirestore(doc))
            .toList());
  }

  /// Mark an email as read
  Future<void> markAsRead(String userId, String emailId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .doc(emailId)
        .update({'read_status': true});
  }

  /// Update email priority manually
  Future<void> updatePriority(
      String userId, String emailId, int newPriority) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_cache')
        .doc(emailId)
        .update({'priority': newPriority});
  }

  // ---------------------------------------------------------------------------
  // ⚙️ SETTINGS OPERATIONS
  // ---------------------------------------------------------------------------

  /// Get user mail settings
  Future<MailSettings> getSettings(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mail_settings')
        .doc('config')
        .get();

    if (doc.exists && doc.data() != null) {
      return MailSettings.fromMap(doc.data()!);
    }
    return const MailSettings(); // Default settings
  }

  /// Update user mail settings
  Future<void> updateSettings(String userId, MailSettings settings) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('mail_settings')
        .doc('config')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // 📏 PRIORITY RULES OPERATIONS
  // ---------------------------------------------------------------------------

  /// Get user-defined priority rules
  Future<List<PriorityRule>> getUserRules(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_priorities')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Ensure ID is present
      return PriorityRule.fromJson(data);
    }).toList();
  }

  /// Add a new priority rule
  Future<void> addRule(String userId, PriorityRule rule) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('email_priorities')
        .doc(); // Auto-generate ID

    await docRef.set({
      'sender': rule.sender,
      'keywords': rule.keywords,
      'priority_score': rule.priorityScore,
    });
  }

  /// Delete a priority rule
  Future<void> deleteRule(String userId, String ruleId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('email_priorities')
        .doc(ruleId)
        .delete();
  }
}
