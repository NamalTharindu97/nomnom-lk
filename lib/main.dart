import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      child: const NomNomApp(),
    );
  }
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
