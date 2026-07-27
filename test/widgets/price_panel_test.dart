import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/widgets/price_panel.dart';
import '../helpers/mocks.dart';

Widget wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Offer offerWithEndDate(int daysFromNow) {
  final base = makeOffer(originalPrice: 1000, offerPrice: 600);
  return base.copyWith(
    endDate: DateTime.now().add(Duration(days: daysFromNow)),
  );
}

void main() {
  group('PricePanel', () {
    testWidgets('renders offer price', (WidgetTester tester) async {
      final offer = makeOffer(offerPrice: 600);
      await tester.pumpWidget(wrapWithApp(PricePanel(offer: offer)));
      await tester.pumpAndSettle();

      expect(find.textContaining('600'), findsWidgets);
    });

    testWidgets('renders original price', (WidgetTester tester) async {
      final offer = makeOffer(originalPrice: 1000);
      await tester.pumpWidget(wrapWithApp(PricePanel(offer: offer)));
      await tester.pumpAndSettle();

      expect(find.textContaining('1,000'), findsWidgets);
    });

    testWidgets('renders save amount', (WidgetTester tester) async {
      final offer = makeOffer(originalPrice: 1000, offerPrice: 600);
      await tester.pumpWidget(wrapWithApp(PricePanel(offer: offer)));
      await tester.pumpAndSettle();

      expect(find.textContaining('400'), findsWidgets);
    });

    testWidgets('shows expiry when ending within 7 days',
        (WidgetTester tester) async {
      final offer = offerWithEndDate(5);
      await tester.pumpWidget(wrapWithApp(PricePanel(offer: offer)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ends in'), findsOneWidget);
    });

    testWidgets('hides expiry when ending beyond 7 days',
        (WidgetTester tester) async {
      final offer = offerWithEndDate(30);
      await tester.pumpWidget(wrapWithApp(PricePanel(offer: offer)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.access_time_rounded), findsNothing);
    });
  });
}
