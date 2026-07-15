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

      // Card width = 800*0.48 = 384px, viewport fits ~2 cards, scroll to see third
      expect(find.text('55%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('10%'), findsOneWidget);
    });

    testWidgets('shows offer title, price, and discount badge on cards',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      // Card width = 800*0.48 = 384px, viewport fits ~2 cards, scroll to see third
      expect(find.text('Premium Burger'), findsOneWidget);
      expect(find.text('Chicken Curry'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Veggie Bowl'), findsOneWidget);
      expect(find.text('Rs. 900'), findsNWidgets(3));
    });

    testWidgets('shows favorite button on each card',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      // Only 2 of 3 cards visible in viewport; scroll to see third card's icon
      await tester.drag(find.byType(ListView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(3));
    });

    testWidgets('shows save amount on each card',
        (WidgetTester tester) async {
      await provider.loadOffers(forceRefresh: true);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      // Premium Burger: 2000→900 saves 1100, Chicken Curry: 1500→900 saves 600
      expect(find.textContaining('Save Rs. 1,100'), findsWidgets);
      expect(find.textContaining('Save Rs. 600'), findsWidgets);
    });
  });

  group('HomeScreen - Hot Offers hidden', () {
    testWidgets('shows carousel when there is only 1 offer',
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

      expect(find.text('Hot Offers'), findsOneWidget);
      expect(find.text('Solo Deal'), findsOneWidget);
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
