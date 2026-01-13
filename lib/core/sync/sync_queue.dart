import 'package:hive_flutter/hive_flutter.dart';

enum SyncAction { create, update, delete }

class SyncOperation {
  final String id;
  final SyncAction action;
  final String collection;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  SyncOperation({
    required this.id,
    required this.action,
    required this.collection,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        'collection': collection,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        id: json['id'],
        action: SyncAction.values.firstWhere((e) => e.name == json['action']),
        collection: json['collection'],
        payload: Map<String, dynamic>.from(json['payload']),
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class SyncQueue {
  static const String boxName = 'sync_queue';

  Future<void> addOperation(SyncOperation op) async {
    final box = await Hive.openBox(boxName);
    await box.add(op.toJson());
  }

  // Methods to pop, peek, and clear operations would go here
  // For brevity, assuming a simple list retrieval for the manager
}
