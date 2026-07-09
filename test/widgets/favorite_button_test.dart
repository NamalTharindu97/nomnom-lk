import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../../lib/providers/offer_provider.dart';
import '../../lib/widgets/favorite_button.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(OfferProvider provider) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChangeNotifierProvider<OfferProvider>.value(
        value: provider,
        child: const FavoriteButton(offerId: '1'),
      ),
    ),
  );
}

void main() {
  group('FavoriteButton', () {
    late OfferProvider provider;

    setUp(() {
      final offer = makeOffer(id: '1', title: 'Test');
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
    });

    testWidgets('shows unfilled heart when offer is not favorite',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('toggles to filled heart on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });
  });
}
