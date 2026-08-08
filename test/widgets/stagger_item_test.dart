import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/widgets/stagger_item.dart';

void main() {
  testWidgets('StaggerItem renders child widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaggerItem(
          index: 0,
          child: const Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('StaggerItem animates in over time', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaggerItem(
          index: 0,
          child: const Text('Animated'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    final fade =
        tester.widget<FadeTransition>(find.byType(FadeTransition).first);

    expect(fade.opacity.value, greaterThan(0.0));
  });

  testWidgets('StaggerItem uses a small fractional slide offset',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaggerItem(index: 0, child: const Text('Offset')),
      ),
    );

    final stagger = find.byType(StaggerItem);
    final slide = tester.widget<SlideTransition>(find.descendant(
      of: stagger,
      matching: find.byType(SlideTransition),
    ));
    expect(slide.position.value.dy, lessThanOrEqualTo(0.04));
    expect(slide.position.value.dy, greaterThanOrEqualTo(0));
  });

  testWidgets('StaggerItem renders immediately with reduced motion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StaggerItem(index: 4, child: Text('Static')),
        ),
      ),
    );

    expect(find.text('Static'), findsOneWidget);
    final stagger = find.byType(StaggerItem);
    expect(
      find.descendant(of: stagger, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: stagger, matching: find.byType(SlideTransition)),
      findsNothing,
    );
  });
}
