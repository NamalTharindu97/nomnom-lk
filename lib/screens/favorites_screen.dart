import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/offer_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/motion_switcher.dart';
import '../widgets/offer_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/stagger_item.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.md,
                18,
                Spacings.md,
                Spacings.sm,
              ),
              child: Text(
                loc.favoritesTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final feedWidth = constraints.maxWidth.clamp(0.0, 600.0);
                  return Center(
                    child: SizedBox(
                      width: feedWidth,
                      height: constraints.maxHeight,
                      child: Consumer2<AuthProvider, OfferProvider>(
                        builder: (context, auth, provider, child) {
                          late final Widget state;
                          if (!auth.isLoggedIn && !auth.isGuest) {
                            state = EmptyState(
                              key: const ValueKey('favorites-auth'),
                              icon: Icons.lock_outline_rounded,
                              title: loc.loginTitle,
                              message: loc.loginEmailHint,
                              onRetry: () => Navigator.of(context)
                                  .pushReplacementNamed(AppRoutes.login),
                              retryLabel: loc.loginSignInButton,
                            );
                          } else if (provider.isLoading &&
                              !provider.hasLoaded) {
                            state = const OfferShimmerList(
                              key: ValueKey('favorites-loading'),
                            );
                          } else if (provider.error != null &&
                              provider.favoriteOffers.isEmpty) {
                            state = RefreshIndicator(
                              key: const ValueKey('favorites-error'),
                              onRefresh: provider.refreshOffers,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: constraints.maxHeight,
                                    child: EmptyState(
                                      icon: Icons.wifi_off_rounded,
                                      title: loc.generalFailedToLoad,
                                      message: provider.error!,
                                      onRetry: provider.refreshOffers,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (provider.favoriteOffers.isEmpty &&
                              provider.hasLoaded) {
                            state = EmptyState(
                              key: const ValueKey('favorites-empty'),
                              icon: Icons.favorite_border_rounded,
                              title: loc.favoritesNoSavedDeals,
                              message: loc.favoritesEmpty,
                            );
                          } else {
                            final offers = provider.favoriteOffers;
                            state = RefreshIndicator(
                              key: const ValueKey('favorites-list'),
                              onRefresh: provider.refreshOffers,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: Spacings.xxs,
                                  bottom: Spacings.md,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: offers.length,
                                itemBuilder: (context, index) {
                                  return StaggerItem(
                                    key: ValueKey(
                                        'favorite-${offers[index].id}'),
                                    index: index,
                                    child: OfferCard(offer: offers[index]),
                                  );
                                },
                              ),
                            );
                          }
                          return MotionSwitcher(child: state);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
