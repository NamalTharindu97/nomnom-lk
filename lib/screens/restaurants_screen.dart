import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Restaurants',
                    style: textTheme.headlineSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Consumer<RestaurantProvider>(
                    builder: (context, provider, _) {
                      if (provider.restaurants.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${provider.total} total',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.curry,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
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
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: EmptyState(
                              icon: Icons.wifi_off_rounded,
                              title: 'Failed to load',
                              message: provider.error!,
                              onRetry: provider.refreshRestaurants,
                            ),
                          ),
                        ],
                      );
                    }

                    final restaurants = provider.restaurants;
                    if (restaurants.isEmpty) {
                      return const EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No restaurants',
                        message: 'No restaurants available right now.',
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
                        padding: const EdgeInsets.only(bottom: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: restaurants.length + (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= restaurants.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            );
                          }
                          return _RestaurantCard(restaurant: restaurants[index]);
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
            const SizedBox(height: 4),
            Text(
              restaurant.address,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            if (restaurant.cuisineTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: restaurant.cuisineTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
