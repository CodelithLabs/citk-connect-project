import 'package:flutter/material.dart';

class AppDurations {
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 750);
  static const Duration slowest = Duration(milliseconds: 1000);
}

class AppCurves {
  static const Curve primary = Curves.easeInOut;
  static const Curve secondary = Curves.easeOut;
  static const Curve tertiary = Curves.easeIn;
}
