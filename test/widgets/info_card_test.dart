import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/widgets/info_card.dart';

void main() {
  group('InfoCard', () {
    const title = 'Revenue';
    const value = 'LKR 12,500';
    const icon = Icons.attach_money_rounded;

    Widget buildSubject() {
      return MaterialApp(
        home: Scaffold(
          body: InfoCard(icon: icon, title: title, value: value),
        ),
      );
    }

    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('renders value', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text(value), findsOneWidget);
    });

    testWidgets('renders icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('renders curry accent bar', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(SizedBox).first,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
    });
  });
}
