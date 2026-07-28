import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/core/theme/app_motion.dart';

void main() {
  testWidgets('uses standard durations when animations are enabled',
      (tester) async {
    late Duration duration;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          duration = AppMotion.duration(context, AppMotion.medium);
          return const SizedBox();
        },
      ),
    ));

    expect(duration, AppMotion.medium);
  });

  testWidgets('uses zero durations when reduced motion is enabled',
      (tester) async {
    late Duration duration;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            duration = AppMotion.duration(context, AppMotion.medium);
            return const SizedBox();
          },
        ),
      ),
    ));

    expect(duration, Duration.zero);
  });
}
