import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/widgets/hot_offer_card.dart';
import '../helpers/mocks.dart';

void main() {
  testWidgets('keeps long pricing content within its clamped narrow card',
      (tester) async {
    final offer = makeOffer(
      id: 'hot',
      title: 'A long hot offer title',
      originalPrice: 99999999,
      offerPrice: 88888888,
    );
    final provider = OfferProvider(
      offerService: MockApiOfferService(offers: [offer]),
      favoritesService: MockApiFavoritesService(),
      favoriteStore: MockFavoriteStore(),
      offerStore: MockOfferStore(),
      connectivityService: MockConnectivityService(),
    );

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<OfferProvider>.value(
          value: provider,
          child: Center(
            child: SizedBox(
              width: 176,
              height: 264,
              child: HotOfferCard(offer: offer, locale: 'en'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.getSize(find.byType(HotOfferCard)), const Size(176, 264));
    expect(find.text('A long hot offer title'), findsOneWidget);
    final savingsText = tester.widget<Text>(find.textContaining('Save'));
    expect(savingsText.maxLines, 2);
    expect(savingsText.overflow, isNull);
    expect(tester.takeException(), isNull);
  });
}
