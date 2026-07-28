import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/app_user.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/screens/favorites_screen.dart';
import '../helpers/mocks.dart';

const _phoneSizes = [
  Size(320, 568),
  Size(390, 844),
  Size(700, 390),
  Size(844, 390),
];

Widget buildTestApp({
  required AuthProvider authProvider,
  required OfferProvider offerProvider,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<OfferProvider>.value(value: offerProvider),
      ],
      child: const FavoritesScreen(),
    ),
  );
}

void main() {
  group('FavoritesScreen', () {
    late AuthProvider authProvider;
    late OfferProvider offerProvider;

    setUp(() {
      authProvider = AuthProvider(MockApiAuthService());
      offerProvider = OfferProvider(
        offerService: MockApiOfferService(offers: []),
        favoritesService: MockApiFavoritesService(),
        favoriteStore: MockFavoriteStore(),
        offerStore: MockOfferStore(),
        connectivityService: MockConnectivityService(),
      );
    });

    testWidgets('shows login gate when not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        offerProvider: offerProvider,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('shows empty state when no favorites',
        (WidgetTester tester) async {
      authProvider.updateUser(const AppUser(
        id: 'u1',
        name: 'Test',
        email: 't@t.com',
        isLoggedIn: true,
      ));
      await offerProvider.loadOffers(forceRefresh: true);

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        offerProvider: offerProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('shows favorites list when has favorites',
        (WidgetTester tester) async {
      final offers = [
        makeOffer(id: '1', title: 'Burger Deal'),
        makeOffer(id: '2', title: 'Pizza Deal'),
      ];
      offerProvider = OfferProvider(
        offerService: MockApiOfferService(offers: offers),
        favoritesService: MockApiFavoritesService(),
        favoriteStore: MockFavoriteStore(),
        offerStore: MockOfferStore(),
        connectivityService: MockConnectivityService(),
      );
      await offerProvider.loadOffers(forceRefresh: true);
      await offerProvider.toggleFavorite('1');
      await offerProvider.toggleFavorite('2');

      authProvider.updateUser(const AppUser(
        id: 'u1',
        name: 'Test',
        email: 't@t.com',
        isLoggedIn: true,
      ));

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        offerProvider: offerProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Burger Deal'), findsOneWidget);
      expect(find.text('Pizza Deal'), findsOneWidget);
    });

    testWidgets('keeps empty content bounded on supported phone viewports',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      authProvider.updateUser(const AppUser(
        id: 'u1',
        name: 'Test',
        email: 't@t.com',
        isLoggedIn: true,
      ));
      await offerProvider.loadOffers(forceRefresh: true);

      for (final size in _phoneSizes) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.pumpWidget(buildTestApp(
          authProvider: authProvider,
          offerProvider: offerProvider,
        ));
        await tester.pump();

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size overflowed');
      }
    });

    testWidgets('keeps the landscape favorites feed one column and bounded',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 390);
      final offers = [makeOffer(id: '1', title: 'Landscape Deal')];
      offerProvider = OfferProvider(
        offerService: MockApiOfferService(offers: offers),
        favoritesService: MockApiFavoritesService(),
        favoriteStore: MockFavoriteStore(),
        offerStore: MockOfferStore(),
        connectivityService: MockConnectivityService(),
      );
      await offerProvider.loadOffers(forceRefresh: true);
      await offerProvider.toggleFavorite('1');
      authProvider.updateUser(const AppUser(
        id: 'u1',
        name: 'Test',
        email: 't@t.com',
        isLoggedIn: true,
      ));

      await tester.pumpWidget(buildTestApp(
        authProvider: authProvider,
        offerProvider: offerProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ListView), findsOneWidget);
      expect(tester.getSize(find.byType(ListView)).width, 600);
      expect(find.text('Landscape Deal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
