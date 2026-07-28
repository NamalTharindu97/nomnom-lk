import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/providers/banner_provider.dart';
import 'package:nomnom_lk/providers/locale_provider.dart';
import 'package:nomnom_lk/providers/notification_provider.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/providers/theme_provider.dart';
import 'package:nomnom_lk/screens/main_shell.dart';
import 'package:nomnom_lk/services/api_client.dart';
import '../helpers/mocks.dart';

Widget buildMainShellApp({
  int initialTab = 0,
  ValueNotifier<int>? initialTabNotifier,
}) {
  final connectivity = MockConnectivityService();
  final offerProvider = OfferProvider(
    offerService: MockApiOfferService(offers: [makeOffer()]),
    favoritesService: MockApiFavoritesService(),
    favoriteStore: MockFavoriteStore(),
    offerStore: MockOfferStore(),
    connectivityService: connectivity,
  );
  final restaurantProvider = RestaurantProvider(
    MockApiRestaurantService(),
    restaurantStore: MockRestaurantStore(),
    connectivityService: connectivity,
  );
  offerProvider.loadOffers(forceRefresh: true);

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: offerProvider),
        ChangeNotifierProvider.value(value: restaurantProvider),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            MockApiNotificationService(),
            notificationStore: MockNotificationStore(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BannerProvider(MockApiBannerService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(MockApiAuthService()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider<ApiClient>.value(value: MockApiClient()),
      ],
      child: initialTabNotifier == null
          ? MainShell(initialTab: initialTab)
          : ValueListenableBuilder<int>(
              valueListenable: initialTabNotifier,
              builder: (_, value, __) => MainShell(initialTab: value),
            ),
    ),
  );
}

void main() {
  testWidgets('retains bottom navigation and selected destination on landscape',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildMainShellApp(initialTab: 2));
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        2);
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab round trip preserves search query and applies focus policy',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildMainShellApp());
    await tester.pump();

    await tester.tap(find.text('Search'));
    await tester.pump();
    final fieldFinder = find.byKey(
      const ValueKey('search-field'),
      skipOffstage: false,
    );
    await tester.enterText(fieldFinder, 'kottu');

    await tester.tap(find.text('Home'));
    await tester.pump();
    var field = tester.widget<TextField>(fieldFinder);
    expect(field.focusNode!.hasFocus, isFalse);
    expect(field.controller!.text, 'kottu');

    await tester.tap(find.text('Search'));
    await tester.pump();
    field = tester.widget<TextField>(fieldFinder);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.text, 'kottu');
    expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1);
  });

  testWidgets('updates the selected destination when initialTab changes',
      (WidgetTester tester) async {
    final initialTab = ValueNotifier<int>(0);
    addTearDown(initialTab.dispose);

    await tester.pumpWidget(
      buildMainShellApp(initialTabNotifier: initialTab),
    );
    await tester.pump();

    initialTab.value = 3;
    await tester.pump();

    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      3,
    );
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
  });
}
