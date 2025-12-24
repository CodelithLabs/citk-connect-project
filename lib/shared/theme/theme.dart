import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
        primaryContainer: Colors.blue[700], // replacement for primaryVariant
        secondaryContainer: Colors.lightBlue[700], // replacement for secondaryVariant
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        primaryContainer: Colors.blue[300], // replacement for primaryVariant
        secondaryContainer: Colors.lightBlue[300], // replacement for secondaryVariant
      ),
      useMaterial3: true,
    );
  }
}
