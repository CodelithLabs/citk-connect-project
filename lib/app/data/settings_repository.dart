import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  // Default to 'system' if null
  String get themeMode => _prefs.getString('themeMode') ?? 'system';

  bool get notificationsEnabled =>
      _prefs.getBool('notificationsEnabled') ?? true;

  Future<void> setThemeMode(String value) async {
    await _prefs.setString('themeMode', value);
  }

  Future<void> setNotifications(bool value) async {
    await _prefs.setBool('notificationsEnabled', value);
  }

  Future<void> resetSettings() async {
    await _prefs.remove('themeMode');
    await _prefs.remove('notificationsEnabled');
  }
}
