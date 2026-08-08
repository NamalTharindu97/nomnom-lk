import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/screens/restaurants_screen.dart';
import '../helpers/mocks.dart';

const _phoneSizes = [
  Size(320, 568),
  Size(390, 844),
  Size(700, 390),
  Size(844, 390),
];

Widget buildTestApp(RestaurantProvider provider) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<RestaurantProvider>.value(
      value: provider,
      child: const RestaurantsScreen(),
    ),
  );
}

void main() {
  group('RestaurantsScreen', () {
    testWidgets('shows restaurant list when loaded',
        (WidgetTester tester) async {
      final provider = RestaurantProvider(
        MockApiRestaurantService(restaurants: [
          makeRestaurant(id: 'r1', name: 'Pizza Hut'),
          makeRestaurant(id: 'r2', name: 'KFC'),
        ]),
        restaurantStore: MockRestaurantStore(),
        connectivityService: MockConnectivityService(),
      );
      await provider.loadRestaurants(forceRefresh: true);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pizza Hut'), findsOneWidget);
      expect(find.text('KFC'), findsOneWidget);
    });

    testWidgets('shows empty state when no restaurants',
        (WidgetTester tester) async {
      final provider = RestaurantProvider(
        MockApiRestaurantService(restaurants: []),
        restaurantStore: MockRestaurantStore(),
        connectivityService: MockConnectivityService(),
      );

      await tester.pumpWidget(buildTestApp(provider));
      // pump past initState loadRestaurants -> shimmer -> final state
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    });

    testWidgets('keeps empty content within parent phone constraints',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = RestaurantProvider(
        MockApiRestaurantService(restaurants: []),
        restaurantStore: MockRestaurantStore(),
        connectivityService: MockConnectivityService(),
      );

      for (final size in _phoneSizes) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size overflowed');
      }
    });

    testWidgets('keeps the landscape restaurant feed one column and bounded',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 390);
      final provider = RestaurantProvider(
        MockApiRestaurantService(restaurants: [
          makeRestaurant(id: 'r1', name: 'Landscape Restaurant'),
        ]),
        restaurantStore: MockRestaurantStore(),
        connectivityService: MockConnectivityService(),
      );
      await provider.loadRestaurants(forceRefresh: true);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ListView), findsOneWidget);
      expect(tester.getSize(find.byType(ListView)).width, 600);
      expect(find.text('Landscape Restaurant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
