import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';
import '../widgets/shimmer_loading.dart';

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
        offers: p.offers,
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
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              );
            }
            return OfferCard(offer: offers[index]);
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: AppLogo(compact: true)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
