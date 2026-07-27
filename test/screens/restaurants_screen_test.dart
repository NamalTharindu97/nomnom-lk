import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/screens/restaurants_screen.dart';
import '../helpers/mocks.dart';

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
  });
}
