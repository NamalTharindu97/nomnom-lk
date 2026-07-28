import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/services/api_platform_service.dart';
import 'package:nomnom_lk/widgets/order_buttons.dart';

Widget wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('OrderButtonsSection', () {
    testWidgets('renders platform display names', (tester) async {
      final platforms = [
        PlatformData(
            id: '1',
            slug: 'uber_eats',
            displayName: 'Uber Eats',
            primaryColor: '#000000',
            deepLinkScheme: 'ubereats://'),
        PlatformData(
            id: '2',
            slug: 'pickme',
            displayName: 'PickMe',
            primaryColor: '#06C167',
            deepLinkScheme: 'pickme://'),
      ];

      await tester.pumpWidget(wrapWithApp(
        OrderButtonsSection(platforms: platforms),
      ));

      expect(find.text('Uber Eats'), findsOneWidget);
      expect(find.text('PickMe'), findsOneWidget);
    });

    testWidgets('renders Order Now heading', (tester) async {
      final platforms = [
        PlatformData(
            id: '1',
            slug: 'uber_eats',
            displayName: 'Uber Eats',
            primaryColor: '#000000',
            deepLinkScheme: 'ubereats://'),
      ];

      await tester.pumpWidget(wrapWithApp(
        OrderButtonsSection(platforms: platforms),
      ));

      expect(find.textContaining('Order'), findsWidgets);
    });

    testWidgets('empty platforms renders nothing', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const OrderButtonsSection(platforms: []),
      ));

      expect(find.byType(Column), findsNothing);
    });

    testWidgets('renders correct number of chevron icons', (tester) async {
      final platforms = [
        PlatformData(
            id: '1',
            slug: 'uber_eats',
            displayName: 'Uber Eats',
            primaryColor: '#000000',
            deepLinkScheme: 'ubereats://'),
        PlatformData(
            id: '2',
            slug: 'pickme',
            displayName: 'PickMe',
            primaryColor: '#06C167',
            deepLinkScheme: 'pickme://'),
      ];

      await tester.pumpWidget(wrapWithApp(
        OrderButtonsSection(platforms: platforms),
      ));

      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });

    testWidgets('renders cart icon in heading', (tester) async {
      final platforms = [
        PlatformData(
            id: '1',
            slug: 'uber_eats',
            displayName: 'Uber Eats',
            primaryColor: '#000000',
            deepLinkScheme: 'ubereats://'),
      ];

      await tester.pumpWidget(wrapWithApp(
        OrderButtonsSection(platforms: platforms),
      ));

      expect(find.byIcon(Icons.shopping_cart_rounded), findsOneWidget);
    });

    testWidgets('wraps long platform labels at 320 width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final platforms = [
        PlatformData(
          id: '1',
          slug: 'other',
          displayName: 'A Very Long Local Food Ordering Platform Name',
          primaryColor: '#000000',
          deepLinkScheme: 'other://',
        ),
      ];

      await tester.pumpWidget(
        wrapWithApp(OrderButtonsSection(platforms: platforms)),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
