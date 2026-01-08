import 'package:citk_connect/app/routing/app_router.dart';
import 'package:citk_connect/common/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'light') state = ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
  }
}

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // 🔔 Initialize Notifications on App Start
    useEffect(() {
      ref.read(notificationServiceProvider).initialize();
      return null;
    }, []);

    // 🎨 Gen Z Dark Theme Definition
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      cardColor: const Color(0xFF181B21),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C63FF),
        surface: Color(0xFF181B21),
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF181B21),
        indicatorColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent, // Removes the M3 grey overlay
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
          }
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF6C63FF));
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
    );

    // ☀️ Light Theme Definition
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        surface: Colors.white,
        onSurface: Colors.black87,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF));
          }
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF6C63FF));
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
    );

    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
    );
  }
}
