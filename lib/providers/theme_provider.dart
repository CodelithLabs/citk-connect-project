import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for theme mode (dark/light)
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark); // Default to dark mode

  /// Toggle between light and dark mode
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Set specific theme mode
  void setTheme(ThemeMode mode) {
    state = mode;
  }

  /// Check if current theme is dark
  bool get isDark => state == ThemeMode.dark;
}
