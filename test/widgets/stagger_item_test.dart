import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/stagger_item.dart';

void main() {
  testWidgets('StaggerItem renders child widget',
      (WidgetTester tester) async {
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

  testWidgets('StaggerItem animates in over time',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaggerItem(
          index: 0,
          child: const Text('Animated'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    final fade = tester
        .widget<FadeTransition>(find.byType(FadeTransition).first);

    expect(fade.opacity.value, greaterThan(0.0));
  });
}
