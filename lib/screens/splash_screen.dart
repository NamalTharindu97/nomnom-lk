import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/offer_provider.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    final offerProvider = context.read<OfferProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    try {
      await Future.wait([
        authProvider.restoreSession(),
        offerProvider.loadOffers(),
        Future<void>.delayed(const Duration(milliseconds: 1100)),
      ]);

      if (mounted && authProvider.isLoggedIn) {
        await Future.wait([
          offerProvider.loadFavorites(),
          notificationProvider.loadUnreadCount(),
        ]);
      }
    } catch (e) {
      debugPrint('Splash bootstrap error: $e');
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacementNamed(
      authProvider.canEnterApp ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: _SplashBody(
        fade: _fade,
        scale: _scale,
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({
    required this.fade,
    required this.scale,
  });

  final Animation<double> fade;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.background,
            context.colors.backgroundAlt,
            const Color(0xFF26130F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(),
                SizedBox(height: 28),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
