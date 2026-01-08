import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;
  SettingsRepository(this._prefs);

  static const _themeModeKey = 'themeMode';
  static const _notificationsKey = 'notifications';

  // Getters and Setters
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  bool get notificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;
  Future<void> setNotifications(bool value) =>
      _prefs.setBool(_notificationsKey, value);

  Future<void> resetSettings() async {
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_notificationsKey);
  }
}
