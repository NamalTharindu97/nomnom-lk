import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/app_routes.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/widgets/offer_card.dart';
import '../helpers/mocks.dart';

Widget buildTestApp({
  required OfferProvider provider,
  required Widget child,
  required MockNavigatorObserver observer,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChangeNotifierProvider<OfferProvider>.value(
        value: provider,
        child: child,
      ),
    ),
    onGenerateRoute: (settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          body: Center(child: Text(settings.name ?? '')),
        ),
      );
    },
    navigatorObservers: [observer],
  );
}

void main() {
  group('OfferCard', () {
    late OfferProvider provider;
    late MockNavigatorObserver observer;
    late Offer offer;

    setUp(() {
      offer = makeOffer(
        id: '42',
        title: 'Test Offer',
        restaurantName: 'Test Restaurant',
        originalPrice: 1000,
        offerPrice: 600,
      );
      final mockOfferService = MockApiOfferService(offers: [offer]);
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
      provider.loadOffers(forceRefresh: true);
      observer = MockNavigatorObserver();
    });

    testWidgets('renders offer title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          provider: provider,
          child: OfferCard(offer: offer),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Offer'), findsOneWidget);
    });

    testWidgets('renders offer price', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          provider: provider,
          child: OfferCard(offer: offer),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('600'), findsWidgets);
    });

    testWidgets('renders restaurant name', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          provider: provider,
          child: OfferCard(offer: offer),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Restaurant'), findsOneWidget);
    });

    testWidgets('renders original price with strikethrough',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          provider: provider,
          child: OfferCard(offer: offer),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1,000'), findsWidgets);
    });

    testWidgets('tapping card navigates to offer details',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          provider: provider,
          child: OfferCard(offer: offer),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).at(0));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(2));
      final route = observer.pushedRoutes.last;
      expect(route.settings.name, AppRoutes.offerDetails);
      expect(route.settings.arguments, '42');
    });
  });
}

class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}
