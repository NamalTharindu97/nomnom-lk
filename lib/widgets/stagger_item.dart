import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

class StaggerItem extends StatefulWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppMotion.short,
    this.offsetY = 0.04,
  });

  final int index;
  final Widget child;
  final Duration duration;
  final double offsetY;

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.index.clamp(0, 5) * 18);
    final total = widget.duration + delay;
    _controller = AnimationController(
      vsync: this,
      duration: total,
    );
    final start = total.inMilliseconds == 0
        ? 0.0
        : delay.inMilliseconds / total.inMilliseconds;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.standardCurve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return RepaintBoundary(child: widget.child);
    }
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.offsetY),
          end: Offset.zero,
        ).animate(_animation),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
