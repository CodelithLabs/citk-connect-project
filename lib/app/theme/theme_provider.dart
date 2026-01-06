import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🌗 GLOBAL THEME PROVIDER
///
/// This provider controls the app-wide ThemeMode.
/// Compatible with:
/// - ref.watch(themeProvider)
/// - ref.read(themeProvider.notifier).toggle()
///
/// Safe, simple, and production-ready.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

/// 🎨 THEME NOTIFIER
///
/// Single source of truth for theme state.
/// Default: Dark mode
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  /// 🔁 Toggle between Dark and Light mode
  ///
  /// Used by UI Switch / Menu actions.
  void toggle() {
    state =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// 🌙 Explicit setters (future-safe, optional)
  void setDark() => state = ThemeMode.dark;

  void setLight() => state = ThemeMode.light;

  void setSystem() => state = ThemeMode.system;
}
