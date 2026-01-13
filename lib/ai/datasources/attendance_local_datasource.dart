import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance_entry_model.dart';

class AttendanceLocalDataSource {
  static const String boxName = 'attendance_entries';

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> cacheEntry(AttendanceEntryModel entry) async {
    final box = await _openBox();
    // Store as JSON map for simplicity in this example
    // In production, register a TypeAdapter
    await box.put(entry.id, {
      ...entry.toJson(),
      'timestamp': entry.timestamp.toIso8601String(),
      'created_at': entry.createdAt.toIso8601String(),
      'is_synced': entry.isSynced,
    });
  }

  Future<List<AttendanceEntryModel>> getEntries() async {
    final box = await _openBox();
    final entries = <AttendanceEntryModel>[];

    for (var key in box.keys) {
      final data = Map<String, dynamic>.from(box.get(key));
      entries.add(AttendanceEntryModel.fromJson(data));
    }

    // Sort by date descending
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }
}
