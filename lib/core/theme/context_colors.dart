import 'package:flutter/material.dart';

import 'app_colors.dart';

class _Colors {
  // Brand
  Color get curry => AppColors.curry;
  Color get chili => AppColors.chili;
  Color get lime => AppColors.lime;
  Color get ocean => AppColors.ocean;

  // Semantic
  Color get success => AppColors.lime;
  Color get warning => AppColors.curry;
  Color get error => AppColors.chili;

  // Muted (theme-aware)
  final Color muted;
  final Color border;
  final Color disabled;

  // Backgrounds
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;

  const _Colors._dark()
      : muted = AppColors.muted,
        border = AppColors.darkBorder,
        disabled = AppColors.darkDisabled,
        background = AppColors.darkBackground,
        backgroundAlt = AppColors.darkBackgroundAlt,
        surface = AppColors.darkSurface,
        surfaceAlt = AppColors.darkSurfaceAlt,
        textPrimary = AppColors.darkTextPrimary,
        textSecondary = AppColors.darkTextSecondary;

  const _Colors._light()
      : muted = AppColors.lightMuted,
        border = AppColors.lightBorder,
        disabled = AppColors.lightDisabled,
        background = AppColors.lightBackground,
        backgroundAlt = AppColors.lightBackgroundAlt,
        surface = AppColors.lightSurface,
        surfaceAlt = AppColors.lightSurfaceAlt,
        textPrimary = AppColors.lightTextPrimary,
        textSecondary = AppColors.lightTextSecondary;
}

extension ThemeColors on BuildContext {
  _Colors get colors {
    final bright = Theme.of(this).brightness;
    return bright == Brightness.dark
        ? const _Colors._dark()
        : const _Colors._light();
  }
}
