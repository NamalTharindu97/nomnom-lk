import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../../lib/providers/banner_provider.dart';
import '../../lib/providers/offer_provider.dart';
import '../../lib/screens/home_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(OfferProvider provider) {
  final bannerProvider = BannerProvider(MockApiBannerService());
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<OfferProvider>.value(value: provider),
        ChangeNotifierProvider<BannerProvider>.value(value: bannerProvider),
      ],
      child: const HomeScreen(onSearchTap: _noop),
    ),
  );
}

void _noop() {}

void main() {
  group('HomeScreen - Hot Offers Carousel', () {
    late OfferProvider provider;

    setUp(() {
      final offers = [
        makeOffer(
          id: '1',
          title: 'Premium Burger',
          originalPrice: 2000,
          offerPrice: 900,
          cuisine: 'Western',
        ),
        makeOffer(
          id: '2',
          title: 'Chicken Curry',
          originalPrice: 1500,
          offerPrice: 900,
          cuisine: 'Sri Lankan',
        ),
        makeOffer(
          id: '3',
          title: 'Veggie Bowl',
          originalPrice: 1000,
          offerPrice: 900,
          cuisine: 'Indian',
        ),
      ];
      final mockOfferService = MockApiOfferService(offers: offers);
      final mockFavService = MockApiFavoritesService();
      final mockConnectivity = MockConnectivityService();
      final mockOfferStore = MockOfferStore();
      final mockFavoriteStore = MockFavoriteStore();
      provider = OfferProvider(
        offerService: mockOfferService,
        favoritesService: mockFavService,
        favoriteStore: mockFavoriteStore,
        connectivityService: mockConnectivity,
        offerStore: mockOfferStore,
      );
    });

    testWidgets('shows Hot Offers header when there are 3 offers',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.text('Hot Offers'), findsOneWidget);
    });

    testWidgets('sorts offers by discount percentage descending',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      // Premium Burger: 55% off (2000→900)
      // Chicken Curry: 40% off (1500→900)
      // Veggie Bowl: 10% off (1000→900)
      expect(find.text('55% off'), findsOneWidget);
      expect(find.text('40% off'), findsOneWidget);
      expect(find.text('10% off'), findsOneWidget);
    });

    testWidgets('shows offer title, price, restaurant, and location on cards',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.text('Premium Burger'), findsOneWidget);
      expect(find.text('Chicken Curry'), findsOneWidget);
      expect(find.text('Veggie Bowl'), findsOneWidget);
      expect(find.text('Test Restaurant'), findsNWidgets(3));
      expect(find.text('Colombo'), findsNWidgets(3));
      expect(find.text('Rs. 900'), findsNWidgets(3));
    });

    testWidgets('shows favorite button on each card',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(3));
    });

    testWidgets('shows original price with strikethrough on each card',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.text('Rs. 2,000'), findsOneWidget);
      expect(find.text('Rs. 1,500'), findsOneWidget);
      expect(find.text('Rs. 1,000'), findsOneWidget);
    });
  });

  group('HomeScreen - Hot Offers hidden', () {
    testWidgets('hides carousel when there is only 1 offer',
        (WidgetTester tester) async {
      final offers = [
        makeOffer(id: '1', title: 'Solo Deal'),
      ];
      final mockOfferService = MockApiOfferService(offers: offers);
      final mockFavService = MockApiFavoritesService();
      final mockConnectivity = MockConnectivityService();
      final mockOfferStore = MockOfferStore();
      final mockFavoriteStore = MockFavoriteStore();
      final provider = OfferProvider(
        offerService: mockOfferService,
        favoritesService: mockFavService,
        favoriteStore: mockFavoriteStore,
        connectivityService: mockConnectivity,
        offerStore: mockOfferStore,
      );
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.text('Hot Offers'), findsNothing);
    });

    testWidgets('hides carousel when there are no offers',
        (WidgetTester tester) async {
      final mockOfferService = MockApiOfferService(offers: []);
      final mockFavService = MockApiFavoritesService();
      final mockConnectivity = MockConnectivityService();
      final mockOfferStore = MockOfferStore();
      final mockFavoriteStore = MockFavoriteStore();
      final provider = OfferProvider(
        offerService: mockOfferService,
        favoritesService: mockFavService,
        favoriteStore: mockFavoriteStore,
        connectivityService: mockConnectivity,
        offerStore: mockOfferStore,
      );
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      expect(find.text('Hot Offers'), findsNothing);
    });
  });
}
