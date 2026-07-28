import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/theme/app_theme.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/providers/banner_provider.dart';
import 'package:nomnom_lk/providers/notification_provider.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/screens/splash_screen.dart';

import '../helpers/mocks.dart';

Widget _buildTestApp({Locale? locale}) {
  final connectivity = MockConnectivityService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(MockApiAuthService()),
      ),
      ChangeNotifierProvider(
        create: (_) => OfferProvider(
          offerService: MockApiOfferService(),
          favoritesService: MockApiFavoritesService(),
          favoriteStore: MockFavoriteStore(),
          offerStore: MockOfferStore(),
          connectivityService: connectivity,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => RestaurantProvider(
          MockApiRestaurantService(),
          restaurantStore: MockRestaurantStore(),
          connectivityService: connectivity,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationProvider(
          MockApiNotificationService(),
          notificationStore: MockNotificationStore(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => BannerProvider(MockApiBannerService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    ),
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size, {
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(_buildTestApp(locale: locale));
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 301));
}

void main() {
  group('SplashScreen adaptive layout', () {
    testWidgets('fits narrow and landscape phone constraints', (tester) async {
      await _pumpAtSize(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(700, 390);
      await tester.pump();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps readable content width', (tester) async {
      await _pumpAtSize(tester, const Size(700, 390));

      expect(
        tester.getSize(find.byKey(const ValueKey('splash-content'))).width,
        440,
      );
      expect(tester.takeException(), isNull);
    });

    for (final locale in const [Locale('si'), Locale('ta')]) {
      testWidgets('fits localized narrow content in ${locale.languageCode}',
          (tester) async {
        await _pumpAtSize(
          tester,
          const Size(320, 568),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
