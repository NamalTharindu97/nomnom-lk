import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

class MotionSwitcher extends StatelessWidget {
  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.medium,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, duration),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.reverseCurve,
      // Remove outgoing state immediately so stale controls cannot remain
      // interactive while the incoming state fades into place.
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
