import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_config.dart';
import 'core/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/offer.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/restaurant_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/offer_details_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_auth_service.dart';
import 'services/api_client.dart';
import 'services/api_favorites_service.dart';
import 'services/api_notification_service.dart';
import 'services/api_offer_service.dart';
import 'services/api_restaurant_service.dart';
import 'services/fcm_messaging_service.dart';
import 'services/sse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (no config): $e');
  }
  runApp(const NomNomBootstrap());
}

class NomNomBootstrap extends StatelessWidget {
  const NomNomBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ApiAuthService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => OfferProvider(
            offerService: ApiOfferService(apiClient),
            favoritesService: ApiFavoritesService(apiClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            ApiNotificationService(apiClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RestaurantProvider(
            ApiRestaurantService(apiClient),
          ),
        ),
      ],
      child: const _FcmInitializer(child: NomNomApp()),
    );
  }
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

  void _navigateToNotifications() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pushNamed(AppRoutes.home);
    } else {
      nav.pushNamed(AppRoutes.home);
    }
  }

  Future<void> _initFcm() async {
    final notificationProvider = context.read<NotificationProvider>();
    try {
      await Firebase.initializeApp();
    } catch (_) {}
    try {
      final apiClient = ApiClient();
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

class _SseListenerState extends State<_SseListener> {
  SSEService? _sseService;
  StreamSubscription<SSEEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSse());
  }

  Future<void> _initSse() async {
    final sse = SSEService(ApiConfig.baseUrl);
    _sseService = sse;
    try {
      await sse.connect();
      _subscription = sse.events.listen(_handleEvent);
    } catch (e) {
      debugPrint('_initSse error: $e');
    }
  }

  void _handleEvent(SSEEvent event) {
    final apiClient = context.read<ApiClient>();
    switch (event.event) {
      case 'offer.created':
      case 'offer.approved':
      case 'offer.updated':
      case 'offer.deleted':
        apiClient.clearCache();
        context.read<OfferProvider>().refreshOffers();
        break;
      case 'restaurant.created':
      case 'restaurant.approved':
      case 'restaurant.updated':
      case 'restaurant.deleted':
        apiClient.clearCache();
        context.read<RestaurantProvider>().loadRestaurants(forceRefresh: true);
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sseService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NomNomApp extends StatelessWidget {
  const NomNomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NomNom LK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.restaurants: (_) => const RestaurantsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.offerDetails) {
          final offerId = switch (settings.arguments) {
            final Offer offer => offer.id,
            final String id => id,
            _ => '',
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
