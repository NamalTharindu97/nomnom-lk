import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/spacings.dart';
import '../widgets/app_logo.dart';
import '../widgets/discount_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_image.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/stagger_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSearchTap,
  });

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: context.read<OfferProvider>().refreshOffers,
        color: context.colors.background,
        backgroundColor: AppColors.curry,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
              context.read<OfferProvider>().loadMoreOffers();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              Selector<OfferProvider, int>(
                selector: (_, p) => p.total,
                builder: (_, total, __) => SliverToBoxAdapter(
                  child: _HomeHeader(
                    offerCount: total,
                    onSearchTap: onSearchTap,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _TrendingCarousel()),
              SliverToBoxAdapter(child: _CuisineFilterChips()),
              _HomeBody(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<OfferProvider, _BodyState>(
      selector: (_, p) => _BodyState(
        error: p.error,
        isLoading: p.isLoading,
        isLoadingMore: p.isLoadingMore,
        offers: p.filteredOffers,
      ),
      builder: (_, state, __) {
        final offers = state.offers;

        if (state.error != null && offers.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Something went wrong',
              message: state.error!,
              onRetry: context.read<OfferProvider>().refreshOffers,
            ),
          );
        }

        if (state.isLoading && offers.isEmpty) {
          return const SliverToBoxAdapter(child: OfferShimmerList());
        }

        if (offers.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.no_food_rounded,
              title: 'No offers yet',
              message: 'Fresh deals will appear here soon.',
            ),
          );
        }

            return SliverList.builder(
              itemCount: offers.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= offers.length) {
                  return Padding(
                    padding: Spacings.padAll,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  );
                }
                return StaggerItem(
                  index: index,
                  child: OfferCard(offer: offers[index]),
                );
              },
            );
      },
    );
  }
}

class _BodyState {
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final List<Offer> offers;

  const _BodyState({
    this.error,
    required this.isLoading,
    required this.isLoadingMore,
    required this.offers,
  });
}

class _CuisineState {
  final List<String> tags;
  final String? selected;

  const _CuisineState({
    required this.tags,
    this.selected,
  });
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.offerCount,
    required this.onSearchTap,
  });

  final int offerCount;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacings.md, 18, Spacings.md, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: AppLogo(compact: true)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.xs, vertical: Spacings.xs),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$offerCount deals',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.curry,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Today near you',
              style: textTheme.headlineSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Street food favorites, lunch packs, and tea-time bites across Sri Lanka.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.sm + 2, vertical: Spacings.sm + 2),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search kottu, hoppers, restaurants',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.curry),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingCarousel extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Selector<OfferProvider, List<Offer>>(
      selector: (_, p) {
        final sorted = List<Offer>.from(p.filteredOffers)
          ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        return sorted.length > 5 ? sorted.sublist(0, 5) : sorted;
      },
      shouldRebuild: (prev, next) => prev != next,
      builder: (_, hotOffers, __) {
        if (hotOffers.length < 2) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Spacings.md, bottom: Spacings.sm),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: AppColors.chili, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Hot Offers',
                    style: textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Spacings.md, right: Spacings.md),
                separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
                itemCount: hotOffers.length,
                itemBuilder: (context, index) {
                  final offer = hotOffers[index];
                  return SizedBox(
                    width: 260,
                    child: Material(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.offerDetails,
                          arguments: offer.id,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: OfferImage(
                                    imageUrl: offer.primaryImage,
                                    borderRadius: BorderRadius.zero,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: Spacings.sm,
                                  left: Spacings.sm,
                                  child: DiscountBadge(label: offer.discountLabel),
                                ),
                                Positioned(
                                  top: 8,
                                  right: Spacings.xs,
                                  child: FavoriteButton(offerId: offer.id),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(Spacings.sm + 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          offer.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleMedium?.copyWith(
                                            color: context.colors.textPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: Spacings.sm),
                                      Text(
                                        CurrencyFormatter.lkr(offer.offerPrice),
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.curry,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Spacings.xs),
                                  Text(
                                    offer.restaurantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: Spacings.xs),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.ocean,
                                        size: 14,
                                      ),
                                      const SizedBox(width: Spacings.xxs),
                                      Expanded(
                                        child: Text(
                                          offer.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.lkr(offer.originalPrice),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.muted,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacings.md),
          ],
        );
      },
    );
  }
}

class _CuisineFilterChips extends StatelessWidget {
  const _CuisineFilterChips();

  @override
  Widget build(BuildContext context) {
    return Selector<OfferProvider, _CuisineState>(
      selector: (_, p) => _CuisineState(
        tags: p.allCuisineTags,
        selected: p.selectedCuisine,
      ),
      shouldRebuild: (prev, next) => prev.selected != next.selected,
      builder: (_, state, __) {
        if (state.tags.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(
            left: Spacings.md,
            right: Spacings.md,
            bottom: Spacings.sm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: state.selected == null,
                  onTap: () => context.read<OfferProvider>().clearCuisineFilter(),
                ),
                ...state.tags.map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(left: Spacings.xs),
                    child: _FilterChip(
                      label: tag,
                      isSelected: state.selected == tag,
                      onTap: () =>
                          context.read<OfferProvider>().filterByCuisine(tag),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm + 2, vertical: Spacings.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.curry : context.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isSelected ? context.colors.background : context.colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
