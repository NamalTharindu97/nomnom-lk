import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const press = Duration(milliseconds: 110);
  static const short = Duration(milliseconds: 170);
  static const medium = Duration(milliseconds: 260);
  static const entrance = Duration(milliseconds: 480);

  static const standardCurve = Curves.easeOutCubic;
  static const reverseCurve = Curves.easeInCubic;

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }

  static Duration duration(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}
