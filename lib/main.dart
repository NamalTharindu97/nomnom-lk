import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/offer.dart';
import 'providers/auth_provider.dart';
import 'providers/offer_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/offer_details_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/favorites_service.dart';
import 'services/mock_offer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NomNomBootstrap());
}

class NomNomBootstrap extends StatelessWidget {
  const NomNomBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => OfferProvider(
            offerService: MockOfferService(),
            favoritesService: FavoritesService(),
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
