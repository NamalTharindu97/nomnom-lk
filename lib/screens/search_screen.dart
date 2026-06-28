import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/restaurant.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';
import '../widgets/shimmer_loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<OfferProvider>().searchOffers(value);
      context.read<RestaurantProvider>().searchRestaurants(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {});
    context.read<OfferProvider>().searchOffers('');
    context.read<RestaurantProvider>().searchRestaurants('');
  }

  void _retrySearch() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      context.read<OfferProvider>().searchOffers(query);
      context.read<RestaurantProvider>().searchRestaurants(query);
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: textTheme.headlineSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    autofocus: false,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Food or restaurant name',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _controller.text.isEmpty
                  ? const _SearchIdleState()
                  : Consumer2<OfferProvider, RestaurantProvider>(
                      builder: (context, offerProvider, restProvider, child) {
                        final isSearching =
                            offerProvider.isSearching || restProvider.isSearching;
                        final offers = offerProvider.searchResults;
                        final restaurants = restProvider.searchResults;
                        final hasError = offerProvider.searchError != null ||
                            restProvider.searchError != null;

                        if (isSearching) {
                          return const OfferShimmerList();
                        }

                        if (hasError && offers.isEmpty && restaurants.isEmpty) {
                          return ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.3,
                                child: EmptyState(
                                  icon: Icons.wifi_off_rounded,
                                  title: 'Search failed',
                                  message: offerProvider.searchError ??
                                      restProvider.searchError!,
                                  onRetry: _retrySearch,
                                ),
                              ),
                            ],
                          );
                        }

                        if (offers.isEmpty && restaurants.isEmpty) {
                          return const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching deals',
                            message: 'Try another food or restaurant name.',
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          children: [
                            if (restaurants.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Restaurants',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...restaurants.map(
                                (r) => _SearchRestaurantTile(restaurant: r),
                              ),
                            ],
                            if (offers.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Offers',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...offers.map((o) => OfferCard(offer: o)),
                            ],
                          ],
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

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_rounded,
      title: 'Find your next meal',
      message: 'Search for food or restaurant names.',
    );
  }
}

class _SearchRestaurantTile extends StatelessWidget {
  const _SearchRestaurantTile({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.curry.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store_rounded, color: AppColors.curry, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (restaurant.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
