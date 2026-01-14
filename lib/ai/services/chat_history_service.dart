// lib/ai/services/chat_history_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ChatHistoryService {
  late Box _box;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _box = await Hive.openBox('chat_history');
  }

  List<Map<String, String>> getHistory() {
    final history = _box.get('messages', defaultValue: <Map<String, String>>[]);
    return List<Map<String, String>>.from(history);
  }

  Future<void> saveHistory(List<Map<String, String>> messages) {
    return _box.put('messages', messages);
  }

  Future<void> clearHistory() {
    return _box.clear();
  }
}
