import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/discount_badge.dart';

void main() {
  group('DiscountBadge', () {
    testWidgets('renders the label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscountBadge(label: '30% off'),
          ),
        ),
      );

      expect(find.text('30% off'), findsOneWidget);
    });

    testWidgets('renders different labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscountBadge(label: 'LKR 400 off'),
          ),
        ),
      );

      expect(find.text('LKR 400 off'), findsOneWidget);
    });
  });
}
