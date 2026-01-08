import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_repository.dart';

part 'settings_provider.g.dart';

// 1. Provider for SharedPreferences instance
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) =>
    throw UnimplementedError();

// 2. Provider for the Repository
@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
}

// 3. State Class
class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  const SettingsState(
      {required this.themeMode, required this.notificationsEnabled});

  SettingsState copyWith({ThemeMode? themeMode, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => themeMode.hashCode ^ notificationsEnabled.hashCode;
}

// 4. Controller (Notifier)
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      themeMode: _parseThemeMode(repo.themeMode),
      notificationsEnabled: repo.notificationsEnabled,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    // 1. Optimistic Update (Update UI immediately)
    state = state.copyWith(themeMode: mode);

    // 2. Persist to storage
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setThemeMode(mode.name);
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }

  Future<void> toggleNotifications(bool value) async {
    // 1. Optimistic Update
    state = state.copyWith(notificationsEnabled: value);

    // 2. Persist
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setNotifications(value);
    } catch (e) {
      debugPrint('Failed to save notifications: $e');
    }
  }

  Future<void> resetToDefaults() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.resetSettings();
    state = SettingsState(
      themeMode: _parseThemeMode(repo.themeMode),
      notificationsEnabled: repo.notificationsEnabled,
    );
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
