import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/providers/offer_provider.dart';
import '../../lib/providers/restaurant_provider.dart';
import '../../lib/screens/search_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp({
  required OfferProvider offerProvider,
  required RestaurantProvider restaurantProvider,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<OfferProvider>.value(value: offerProvider),
        ChangeNotifierProvider<RestaurantProvider>.value(value: restaurantProvider),
      ],
      child: const SearchScreen(),
    ),
  );
}

void main() {
  group('SearchScreen', () {
    late OfferProvider offerProvider;
    late RestaurantProvider restaurantProvider;

    setUp(() {
      final offers = [
        makeOffer(id: '1', title: 'Chicken Curry', cuisine: 'Sri Lankan'),
        makeOffer(id: '2', title: 'Pizza', cuisine: 'Italian'),
      ];
      final restaurants = [
        makeRestaurant(id: 'r1', name: 'Curry House'),
      ];
      final mockOfferService = MockApiOfferService(offers: offers);
      final mockFavService = MockApiFavoritesService();
      final mockRestService = MockApiRestaurantService(restaurants: restaurants);

      offerProvider = OfferProvider(
        offerService: mockOfferService,
        favoritesService: mockFavService,
      );
      restaurantProvider = RestaurantProvider(mockRestService);
      offerProvider.loadOffers(forceRefresh: true);
      restaurantProvider.loadRestaurants(forceRefresh: true);
    });

    testWidgets('shows idle state when no query and no recent searches',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
      ));
      await tester.pump();

      expect(find.text('What are you craving?'), findsOneWidget);
      expect(find.text('Recent'), findsNothing);
    });

    testWidgets('shows recent search chips after searching',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Chicken');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);
    });

    testWidgets('tapping recent chip fills search field and triggers search',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Pizza');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Pizza'), findsOneWidget);

      await tester.tap(find.text('Pizza'));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Pizza');
    });

    testWidgets('clear all removes all recent searches',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Chicken');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('Chicken'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pump();

      expect(find.text('Chicken'), findsNothing);
      expect(find.text('What are you craving?'), findsOneWidget);
    });
  });
}
