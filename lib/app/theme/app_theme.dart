import 'package:citk_connect/app/theme/app_colors.dart';
import 'package:citk_connect/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
  ),
  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.primary,
    headlineMedium: AppTextStyles.primary,
    headlineSmall: AppTextStyles.primary,
    titleLarge: AppTextStyles.primary,
    titleMedium: AppTextStyles.primary,
    titleSmall: AppTextStyles.primary,
    bodyLarge: AppTextStyles.primary,
    bodyMedium: AppTextStyles.primary,
    bodySmall: AppTextStyles.primary,
  ),
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    surface: AppColors.surfaceInverse,
    onSurface: AppColors.onSurfaceInverse,
  ),
  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.primary,
    headlineMedium: AppTextStyles.primary,
    headlineSmall: AppTextStyles.primary,
    titleLarge: AppTextStyles.primary,
    titleMedium: AppTextStyles.primary,
    titleSmall: AppTextStyles.primary,
    bodyLarge: AppTextStyles.primary,
    bodyMedium: AppTextStyles.primary,
    bodySmall: AppTextStyles.primary,
  ),
);
