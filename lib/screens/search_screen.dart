import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/restaurant.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/stagger_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _recentSearches = <String>[];
  Timer? _debounce;

  static const _maxRecent = 8;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isNotEmpty) {
        _addToRecent(value.trim());
      }
      context.read<OfferProvider>().searchOffers(value);
      context.read<RestaurantProvider>().searchRestaurants(value);
    });
  }

  void _addToRecent(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > _maxRecent) {
      _recentSearches.removeLast();
    }
  }

  void _onRecentTap(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _focusNode.requestFocus();
    _onSearchChanged(query);
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {});
    context.read<OfferProvider>().searchOffers('');
    context.read<RestaurantProvider>().searchRestaurants('');
  }

  void _clearRecent() {
    setState(() => _recentSearches.clear());
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
              padding: const EdgeInsets.fromLTRB(Spacings.md, 18, Spacings.md, Spacings.sm),
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
                  const SizedBox(height: Spacings.sm + 2),
                  TextField(
                    key: const ValueKey('search-field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addToRecent(value.trim());
                        context.read<OfferProvider>().searchOffers(value);
                        context.read<RestaurantProvider>().searchRestaurants(value);
                      }
                    },
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
                  ? _SearchIdleState(
                      recentSearches: _recentSearches,
                      onRecentTap: _onRecentTap,
                      onClearRecent: _clearRecent,
                    )
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
                            title: 'No deals found',
                            message: 'Try another dish or restaurant name.',
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.only(top: Spacings.xxs, bottom: Spacings.md),
                          children: [
                            if (restaurants.isNotEmpty) ...[
                              Padding(
                              padding: const EdgeInsets.fromLTRB(Spacings.md, Spacings.xs, Spacings.md, Spacings.xxs),
                                  child: Text(
                                'Restaurants',
                                style: textTheme.titleSmall?.copyWith(
                                    color: context.colors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...restaurants.map(
                                (r) => StaggerItem(
                                  index: 0,
                                  child: _SearchRestaurantTile(restaurant: r),
                                ),
                              ),
                            ],
                            if (offers.isNotEmpty) ...[
                              Padding(
                              padding: const EdgeInsets.fromLTRB(Spacings.md, Spacings.xs, Spacings.md, Spacings.xxs),
                                  child: Text(
                                'Offers',
                                style: textTheme.titleSmall?.copyWith(
                                    color: context.colors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...offers.asMap().entries.map(
                                (e) => StaggerItem(
                                  index: e.key,
                                  child: OfferCard(offer: e.value),
                                ),
                              ),
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
  const _SearchIdleState({
    required this.recentSearches,
    required this.onRecentTap,
    required this.onClearRecent,
  });

  final List<String> recentSearches;
  final void Function(String query) onRecentTap;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isNotEmpty) {
      final textTheme = Theme.of(context).textTheme;
      return ListView(
        padding: const EdgeInsets.fromLTRB(Spacings.md, Spacings.sm, Spacings.md, Spacings.xxl),
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: context.colors.muted),
              const SizedBox(width: Spacings.xs),
              Text(
                'Recent',
                style: textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClearRecent,
                child: Text(
                  'Clear all',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.chili,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.xs - 2,
            runSpacing: Spacings.xs - 2,
            children: recentSearches.map(
              (q) => ActionChip(
                avatar: const Icon(Icons.schedule_rounded, size: 16),
                label: Text(q, style: textTheme.bodySmall),
                onPressed: () => onRecentTap(q),
                side: BorderSide(
                  color: context.colors.surfaceAlt,
                ),
              ),
            ).toList(),
          ),
        ],
      );
    }

    return const EmptyState(
      icon: Icons.search_rounded,
      title: 'What are you craving?',
      message: 'Search for dishes, restaurants, or cuisines.',
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
      padding: const EdgeInsets.fromLTRB(Spacings.md, 0, Spacings.md, Spacings.xs),
      child: Container(
        padding: const EdgeInsets.all(Spacings.sm + 2),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
           border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.08)),
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
            const SizedBox(width: Spacings.sm),
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
                      style: textTheme.bodySmall?.copyWith(color: context.colors.muted),
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
