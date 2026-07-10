import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Brand (same in both modes)
  static const curry = Color(0xFFFFB23F);
  static const chili = Color(0xFFE84B35);
  static const lime = Color(0xFF77C65D);
  static const ocean = Color(0xFF23A6A0);
  static const muted = Color(0xFF9F998E);

  // Dark mode
  static const darkBackground = Color(0xFF0A0A09);
  static const darkBackgroundAlt = Color(0xFF11110F);
  static const darkSurface = Color(0xFF1A1A17);
  static const darkSurfaceAlt = Color(0xFF23231F);
  static const darkTextPrimary = Color(0xFFFFF4DF);
  static const darkTextSecondary = Color(0xFFE7DDD0);
  static const darkBorder = Color(0xFF3A3A33);
  static const darkDisabled = Color(0xFF55534D);

  // Light mode
  static const lightBackground = Color(0xFFFAF7F1);
  static const lightBackgroundAlt = Color(0xFFF0EDE6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF5F5F0);
  static const lightTextPrimary = Color(0xFF1C1B19);
  static const lightTextSecondary = Color(0xFF6B6560);
  static const lightMuted = Color(0xFF6E6960);
  static const lightBorder = Color(0xFFE0DDD5);
  static const lightDisabled = Color(0xFFC4C1B8);

  // Legacy aliases (used by some hardcoded spots)
  @Deprecated('Use context.colors instead') static const deepCharcoal = darkBackground;
  @Deprecated('Use context.colors instead') static const charcoal = darkBackgroundAlt;
  @Deprecated('Use context.colors instead') static const cardDark = darkSurface;
  @Deprecated('Use context.colors instead') static const cardElevated = darkSurfaceAlt;
  @Deprecated('Use context.colors instead') static const cream = darkTextPrimary;
  @Deprecated('Use context.colors instead') static const coconut = darkTextSecondary;
}
