import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/offer_image.dart';

void main() {
  group('OfferImage', () {
    testWidgets('shows fallback icon when imageUrl is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfferImage(
              imageUrl: '',
              height: 100,
              width: 100,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_dining_rounded), findsOneWidget);
    });
  });
}
