import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/core/app_routes.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/screens/search_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp({
  required OfferProvider offerProvider,
  required RestaurantProvider restaurantProvider,
  Widget searchScreen = const SearchScreen(),
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routes: {
      AppRoutes.restaurants: (_) => const Scaffold(
            body: Text('Restaurants route'),
          ),
    },
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<OfferProvider>.value(value: offerProvider),
        ChangeNotifierProvider<RestaurantProvider>.value(
            value: restaurantProvider),
      ],
      child: searchScreen,
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
      final mockRestService =
          MockApiRestaurantService(restaurants: restaurants);
      final mockConnectivity = MockConnectivityService();
      final mockOfferStore = MockOfferStore();
      final mockRestaurantStore = MockRestaurantStore();
      final mockFavoriteStore = MockFavoriteStore();

      offerProvider = OfferProvider(
        offerService: mockOfferService,
        favoritesService: mockFavService,
        favoriteStore: mockFavoriteStore,
        connectivityService: mockConnectivity,
        offerStore: mockOfferStore,
      );
      restaurantProvider = RestaurantProvider(
        mockRestService,
        restaurantStore: mockRestaurantStore,
        connectivityService: mockConnectivity,
      );
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
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Chicken'), findsNothing);
      expect(find.text('What are you craving?'), findsOneWidget);
    });

    testWidgets('active state controls focus without losing the query',
        (WidgetTester tester) async {
      var isActive = false;
      var focusRequest = 0;
      late StateSetter updateHost;

      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
        searchScreen: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return SearchScreen(
              isActive: isActive,
              focusRequest: focusRequest,
            );
          },
        ),
      ));
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('search-field')))
            .focusNode!
            .hasFocus,
        isFalse,
      );

      updateHost(() {
        isActive = true;
        focusRequest++;
      });
      await tester.pump();
      await tester.enterText(
          find.byKey(const ValueKey('search-field')), 'Pizza');

      updateHost(() => isActive = false);
      await tester.pump();
      final hiddenField = tester.widget<TextField>(
        find.byKey(const ValueKey('search-field')),
      );
      expect(hiddenField.focusNode!.hasFocus, isFalse);
      expect(hiddenField.controller!.text, 'Pizza');

      updateHost(() {
        isActive = true;
        focusRequest++;
      });
      await tester.pump();
      final selectedField = tester.widget<TextField>(
        find.byKey(const ValueKey('search-field')),
      );
      expect(selectedField.focusNode!.hasFocus, isTrue);
      expect(selectedField.controller!.text, 'Pizza');
    });

    testWidgets('restaurant result opens the restaurants route',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        offerProvider: offerProvider,
        restaurantProvider: restaurantProvider,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Curry');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Curry House'));
      await tester.pumpAndSettle();

      expect(find.text('Restaurants route'), findsOneWidget);
    });

    testWidgets('has no layout exceptions at compact and landscape sizes',
        (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;

      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(700, 390),
        Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(buildTestApp(
          offerProvider: offerProvider,
          restaurantProvider: restaurantProvider,
          locale: const Locale('ta'),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed at $size');
      }
    });
  });
}
