import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../ai/datasources/attendance_remote_datasource.dart';
import '../../ai/models/attendance_entry_model.dart';
import 'sync_queue.dart';

final syncManagerProvider = Provider((ref) => SyncManager());

class SyncManager {
  final _remoteDataSource = AttendanceRemoteDataSource();
  bool _isSyncing = false;

  SyncManager() {
    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processQueue();
      }
    });
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final box = await Hive.openBox(SyncQueue.boxName);
      if (box.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Process items one by one (FIFO)
      // In a real app, you'd handle retries and batching
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final opData = Map<String, dynamic>.from(box.get(key));
        final op = SyncOperation.fromJson(opData);

        try {
          if (op.collection == 'attendance_entries' &&
              op.action == SyncAction.create) {
            final entry = AttendanceEntryModel.fromJson(op.payload);
            await _remoteDataSource.uploadEntry(entry);
            keysToDelete.add(key);
          }
        } catch (e) {
          // Log error, maybe skip or retry later
        }
      }

      await box.deleteAll(keysToDelete);
    } finally {
      _isSyncing = false;
    }
  }
}
