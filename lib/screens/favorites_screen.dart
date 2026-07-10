import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/offer_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';
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
              padding: const EdgeInsets.fromLTRB(Spacings.md, 18, Spacings.md, Spacings.sm),
              child: Text(
                loc.favoritesTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Consumer2<AuthProvider, OfferProvider>(
                builder: (context, auth, provider, child) {
                  if (!auth.isLoggedIn && !auth.isGuest) {
                    return EmptyState(
                      icon: Icons.lock_outline_rounded,
                      title: loc.loginTitle,
                      message: loc.loginEmailHint,
                      onRetry: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                      retryLabel: loc.loginSignInButton,
                    );
                  }

                  if (provider.isLoading && !provider.hasLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.favoriteOffers.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: provider.refreshOffers,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
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
                  }

                  final offers = provider.favoriteOffers;

                  if (offers.isEmpty && provider.hasLoaded) {
                    return EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: loc.favoritesNoSavedDeals,
                      message: loc.favoritesEmpty,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.refreshOffers,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: Spacings.xxs, bottom: Spacings.md),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        return StaggerItem(
                          index: index,
                          child: OfferCard(offer: offers[index]),
                        );
                      },
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
