import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/stagger_item.dart';

String _resolveError(String token, AppLocalizations loc) {
  switch (token) {
    case 'failedLoadPullRetry':
      return loc.generalLoadingFailedPullToRestart;
    case 'noInternet':
      return loc.generalNoInternetConnection;
    default:
      return loc.generalError;
  }
}

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context)!.restaurantsTitle),
        actions: [
          Consumer<RestaurantProvider>(
            builder: (context, provider, _) {
              if (provider.restaurants.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: Spacings.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.xs,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.restaurantsTotal(provider.total),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.curry,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<RestaurantProvider>().refreshRestaurants(),
                color: context.colors.background,
                backgroundColor: AppColors.curry,
                child: Consumer<RestaurantProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const RestaurantShimmerList();
                    }

                    if (provider.error != null) {
                      final loc = AppLocalizations.of(context)!;
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: EmptyState(
                              icon: Icons.wifi_off_rounded,
                              title: loc.restaurantsFailedToLoad,
                              message: _resolveError(provider.error!, loc),
                              onRetry: provider.refreshRestaurants,
                            ),
                          ),
                        ],
                      );
                    }

                    final restaurants = provider.restaurants;
                    if (restaurants.isEmpty) {
                      return EmptyState(
                        icon: Icons.storefront_outlined,
                        title: AppLocalizations.of(context)!.restaurantsEmpty,
                        message: AppLocalizations.of(context)!.restaurantsFailedToLoad,
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.pixels >=
                                notification.metrics.maxScrollExtent - 200) {
                          provider.loadMoreRestaurants();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: Spacings.md),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: restaurants.length + (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= restaurants.length) {
                            return const Padding(
                              padding: EdgeInsets.all(Spacings.md),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            );
                          }
                          return StaggerItem(
                            index: index,
                            child: _RestaurantCard(restaurant: restaurants[index]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacings.md, 0, Spacings.md, Spacings.sm),
      child: Container(
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
           border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Spacings.xxs),
            Text(
              restaurant.address,
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.muted,
              ),
            ),
            if (restaurant.cuisineTags.isNotEmpty) ...[
              const SizedBox(height: Spacings.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: Spacings.xxs,
                    children: restaurant.cuisineTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.xs,
                          vertical: Spacings.xxs,
                        ),
                    decoration: BoxDecoration(
                      color: AppColors.curry.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.curry,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
