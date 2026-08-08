import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/api_config.dart';
import 'core/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'models/offer.dart';
import 'providers/auth_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/platform_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/notification_prefs_screen.dart';
import 'screens/offer_details_screen.dart';
import 'screens/register_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/api_auth_service.dart';
import 'services/api_banner_service.dart';
import 'services/api_client.dart';
import 'services/api_favorites_service.dart';
import 'services/api_notification_service.dart';
import 'services/api_offer_service.dart';
import 'services/api_restaurant_service.dart';
import 'services/connectivity_service.dart';
import 'services/fcm_messaging_service.dart';
import 'services/local/favorite_store.dart';
import 'services/local/notification_store.dart';
import 'services/local/offer_store.dart';
import 'services/local/restaurant_store.dart';
import 'services/sse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (no config): $e');
  }
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  if (ApiConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = ApiConfig.sentryDsn;
      options.environment = ApiConfig.appEnv;
      options.release = ApiConfig.buildSha;
      options.tracesSampleRate = 0.2;
    },
        appRunner: () => runApp(NomNomBootstrap(
            themeProvider: themeProvider, localeProvider: localeProvider)));
  } else {
    runApp(NomNomBootstrap(
        themeProvider: themeProvider, localeProvider: localeProvider));
  }
}

class NomNomBootstrap extends StatelessWidget {
  const NomNomBootstrap(
      {super.key, required this.themeProvider, required this.localeProvider});

  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final connectivityService = ConnectivityService();
    final offerStore = OfferStore();
    final restaurantStore = RestaurantStore();
    final favoriteStore = FavoriteStore();
    final notificationStore = NotificationStore();
    final offerProvider = OfferProvider(
      offerService: ApiOfferService(apiClient),
      favoritesService: ApiFavoritesService(apiClient),
      favoriteStore: favoriteStore,
      offerStore: offerStore,
      connectivityService: connectivityService,
    );
    offerProvider.setLocaleProvider(localeProvider);
    final notificationProvider = NotificationProvider(
      ApiNotificationService(apiClient),
      notificationStore: notificationStore,
    );
    final restaurantProvider = RestaurantProvider(
      ApiRestaurantService(apiClient),
      restaurantStore: restaurantStore,
      connectivityService: connectivityService,
    );
    final authProvider = AuthProvider(
      ApiAuthService(apiClient),
      apiClient: apiClient,
      favoriteStore: favoriteStore,
      notificationStore: notificationStore,
      offerStore: offerStore,
      restaurantStore: restaurantStore,
      onAccountCleared: () {
        offerProvider.resetForAccountChange();
        notificationProvider.resetForAccountChange();
      },
    );

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<OfferStore>.value(value: offerStore),
        Provider<RestaurantStore>.value(value: restaurantStore),
        Provider<FavoriteStore>.value(value: favoriteStore),
        Provider<NotificationStore>.value(value: notificationStore),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => offerProvider),
        ChangeNotifierProvider(create: (_) => notificationProvider),
        ChangeNotifierProvider(create: (_) => restaurantProvider),
        ChangeNotifierProvider(
          create: (_) => BannerProvider(ApiBannerService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => PlatformProvider(apiClient),
        ),
      ],
      child:
          const _StoreInitializer(child: _FcmInitializer(child: NomNomApp())),
    );
  }
}

class _StoreInitializer extends StatefulWidget {
  final Widget child;
  const _StoreInitializer({required this.child});

  @override
  State<_StoreInitializer> createState() => _StoreInitializerState();
}

class _StoreInitializerState extends State<_StoreInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStores());
  }

  Future<void> _initStores() async {
    await context.read<OfferStore>().init();
    await context.read<RestaurantStore>().init();
    await context.read<FavoriteStore>().init();
    await context.read<NotificationStore>().init();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FcmInitializer extends StatefulWidget {
  final Widget child;
  const _FcmInitializer({required this.child});

  @override
  State<_FcmInitializer> createState() => _FcmInitializerState();
}

class _FcmInitializerState extends State<_FcmInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFcm());
  }

  void _navigateToNotifications(Map<String, dynamic>? data) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (data == null || data.isEmpty) {
      nav.pushNamed(AppRoutes.home);
      return;
    }
    final offerId = data['offer_id'];
    if (offerId != null && offerId is String && offerId.isNotEmpty) {
      nav.pushNamed(AppRoutes.offerDetails, arguments: offerId);
      return;
    }
    final restaurantId = data['restaurant_id'];
    if (restaurantId != null &&
        restaurantId is String &&
        restaurantId.isNotEmpty) {
      nav.pushNamed(AppRoutes.restaurants);
      return;
    }
    final type = data['type'];
    if (type == 'admin') {
      nav.pushNamed(AppRoutes.home, arguments: 3);
      return;
    }
    nav.pushNamed(AppRoutes.home);
  }

  Future<void> _initFcm() async {
    final notificationProvider = context.read<NotificationProvider>();
    final apiClient = context.read<ApiClient>();
    try {
      final fcm = FcmMessagingService(
        apiClient: apiClient,
        notificationProvider: notificationProvider,
      );
      await fcm.initialize(onNavigate: _navigateToNotifications);
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) => _SseListener(child: widget.child);
}

class _SseListener extends StatefulWidget {
  final Widget child;
  const _SseListener({required this.child});

  @override
  State<_SseListener> createState() => _SseListenerState();
}

class _SseListenerState extends State<_SseListener>
    with WidgetsBindingObserver {
  SSEService? _sseService;
  StreamSubscription<SSEEvent>? _subscription;
  Timer? _debounce;
  Timer? _pollTimer;
  bool _needsOfferRefresh = false;
  bool _needsFavoriteRefresh = false;
  bool _needsRestaurantRefresh = false;
  bool _needsBannerRefresh = false;
  bool _hasSseConnection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSse());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfNeeded();
    }
  }

  void _refreshIfNeeded() {
    final apiClient = context.read<ApiClient>();
    apiClient.invalidateCache('/banners/active');
    context.read<BannerProvider>().refreshBanners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      apiClient.invalidateCache('/offers');
      _refreshOffersForSession();
      apiClient.invalidateCache('/restaurants');
      context.read<RestaurantProvider>().loadRestaurants(forceRefresh: true);
    });
  }

  void _refreshOffersForSession() {
    final offerProvider = context.read<OfferProvider>();
    if (context.read<AuthProvider>().isLoggedIn) {
      offerProvider.refreshOffers();
    } else {
      offerProvider.loadOffers(forceRefresh: true);
    }
  }

  Future<void> _initSse() async {
    final sse = SSEService(ApiConfig.baseUrl);
    _sseService = sse;
    try {
      await sse.connect();
      _hasSseConnection = sse.isConnected;
      _subscription = sse.events.listen(_handleEvent);
    } catch (e) {
      debugPrint('_initSse error: $e');
    }
    _startPolling();
  }

  void _handleEvent(SSEEvent event) {
    _hasSseConnection = true;
    debugPrint('SSE event: ${event.event} ${event.data}');
    switch (event.event) {
      case 'offer.created':
      case 'offer.approved':
      case 'offer.updated':
      case 'offer.deleted':
      case 'offer.rejected':
      case 'offer.expired':
        _needsOfferRefresh = true;
        _needsBannerRefresh = true;
        break;
      case 'restaurant.created':
      case 'restaurant.approved':
      case 'restaurant.updated':
      case 'restaurant.deleted':
      case 'restaurant.rejected':
        _needsRestaurantRefresh = true;
        break;
      case 'banner.created':
      case 'banner.updated':
      case 'banner.approved':
      case 'banner.rejected':
      case 'banner.deleted':
        _needsBannerRefresh = true;
        break;
      case 'favorite.added':
      case 'favorite.removed':
        final eventUserId = event.data['user_id']?.toString();
        final activeUserId = context.read<AuthProvider>().user?.id;
        if (eventUserId == activeUserId) {
          _needsOfferRefresh = true;
          _needsFavoriteRefresh = true;
        }
        break;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _flushEvents);
  }

  void _flushEvents() {
    final apiClient = context.read<ApiClient>();
    if (_needsOfferRefresh) {
      apiClient.invalidateCache('/offers');
      if (_needsFavoriteRefresh) {
        apiClient.invalidateCache('/favorites');
        _needsFavoriteRefresh = false;
      }
      _refreshOffersForSession();
      _needsOfferRefresh = false;
    }
    if (_needsRestaurantRefresh) {
      apiClient.invalidateCache('/restaurants');
      context.read<RestaurantProvider>().loadRestaurants(forceRefresh: true);
      _needsRestaurantRefresh = false;
    }
    if (_needsBannerRefresh) {
      apiClient.invalidateCache('/banners/active');
      context.read<BannerProvider>().refreshBanners();
      _needsBannerRefresh = false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_hasSseConnection) return;
      _refreshIfNeeded();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _debounce?.cancel();
    _subscription?.cancel();
    _sseService?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NomNomApp extends StatelessWidget {
  const NomNomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      title: 'NomNom LK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        final textScaler = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.75, maxScaleFactor: 1.5);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('si'),
        const Locale('ta'),
      ],
      locale: context.watch<LocaleProvider>().locale,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.restaurants: (_) => const RestaurantsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.verifyEmail) {
          final email = switch (settings.arguments) {
            final String e => e,
            _ => '',
          };
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => VerifyEmailScreen(email: email),
          );
        }

        if (settings.name == AppRoutes.home) {
          final initialTab = switch (settings.arguments) {
            final int tab => tab,
            _ => 0,
          };
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => MainShell(initialTab: initialTab),
          );
        }

        if (settings.name == AppRoutes.editProfile) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const EditProfileScreen(),
          );
        }

        if (settings.name == AppRoutes.notificationPrefs) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const NotificationPrefsScreen(),
          );
        }

        if (settings.name == AppRoutes.offerDetails ||
            settings.name?.startsWith('/offer/') == true) {
          final offerId = switch (settings.arguments) {
            final Offer offer => offer.id,
            final String id => id,
            _ => settings.name?.split('/').last ?? '',
          };
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => OfferDetailsScreen(offerId: offerId),
          );
        }

        return null;
      },
    );
  }
}
