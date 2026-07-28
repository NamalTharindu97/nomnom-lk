import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nomnom_lk/core/app_routes.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/app_user.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/providers/locale_provider.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/providers/platform_provider.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/providers/theme_provider.dart';
import 'package:nomnom_lk/screens/edit_profile_screen.dart';
import 'package:nomnom_lk/screens/notification_prefs_screen.dart';
import 'package:nomnom_lk/screens/offer_details_screen.dart';
import 'package:nomnom_lk/screens/profile_screen.dart';
import 'package:nomnom_lk/services/api_client.dart';

import '../helpers/mocks.dart';

const _phoneSizes = [
  Size(320, 568),
  Size(390, 844),
  Size(700, 390),
  Size(844, 390),
];

OfferProvider _offerProvider({List<Offer> offers = const []}) {
  return OfferProvider(
    offerService: MockApiOfferService(offers: offers),
    favoritesService: MockApiFavoritesService(),
    favoriteStore: MockFavoriteStore(),
    offerStore: MockOfferStore(),
    connectivityService: MockConnectivityService(),
  );
}

RestaurantProvider _restaurantProvider() {
  return RestaurantProvider(
    MockApiRestaurantService(),
    restaurantStore: MockRestaurantStore(),
    connectivityService: MockConnectivityService(),
  );
}

Widget _app({
  required Widget home,
  required AuthProvider authProvider,
  required OfferProvider offerProvider,
  MockApiClient? apiClient,
}) {
  final client = apiClient ?? MockApiClient();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: offerProvider),
      ChangeNotifierProvider(create: (_) => _restaurantProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => PlatformProvider(client)),
      Provider<ApiClient>.value(value: client),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.notificationPrefs: (_) => const NotificationPrefsScreen(),
      },
      home: home,
    ),
  );
}

Future<void> _verifySizes(
  WidgetTester tester,
  Widget Function() build,
) async {
  addTearDown(tester.view.reset);
  for (final size in _phoneSizes) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: 'overflow at $size');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('offer details adapts across supported phone sizes',
      (tester) async {
    final offer = makeOffer(
      title: 'A very long daily food offer title that must wrap safely',
      originalPrice: 125000,
      offerPrice: 99999,
    );
    final offers = _offerProvider(offers: [offer]);
    await offers.loadOffers();
    final auth = AuthProvider(MockApiAuthService());

    await _verifySizes(
      tester,
      () => _app(
        home: OfferDetailsScreen(offerId: offer.id),
        authProvider: auth,
        offerProvider: offers,
      ),
    );
  });

  testWidgets('profile adapts and opens notification preferences',
      (tester) async {
    final auth = AuthProvider(MockApiAuthService());
    await auth.continueAsGuest();
    final offers = _offerProvider();

    await _verifySizes(
      tester,
      () => _app(
        home: const ProfileScreen(),
        authProvider: auth,
        offerProvider: offers,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Notification Preferences'),
      300,
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Notification Preferences'));
    await tester.pump();
    await tester.tap(find.text('Notification Preferences'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPrefsScreen), findsOneWidget);
  });

  testWidgets('edit profile remains scrollable with a keyboard on short phones',
      (tester) async {
    final auth = AuthProvider(MockApiAuthService());
    auth.updateUser(const AppUser(
      id: 'u1',
      name: 'Adaptive User',
      email: 'adaptive@example.com',
      isLoggedIn: true,
    ));
    final offers = _offerProvider();
    final client = MockApiClient();

    await _verifySizes(
      tester,
      () => _app(
        home: const EditProfileScreen(),
        authProvider: auth,
        offerProvider: offers,
        apiClient: client,
      ),
    );

    tester.view.physicalSize = const Size(700, 390);
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.pump();
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
  });

  testWidgets('notification preferences adapts across supported phone sizes',
      (tester) async {
    final auth = AuthProvider(MockApiAuthService());
    final offers = _offerProvider();

    await _verifySizes(
      tester,
      () => _app(
        home: const NotificationPrefsScreen(),
        authProvider: auth,
        offerProvider: offers,
      ),
    );
    expect(find.byType(Switch), findsNWidgets(3));
  });
}
