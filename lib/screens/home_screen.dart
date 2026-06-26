import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
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
      body: Consumer<OfferProvider>(
        builder: (context, provider, child) {
          final offers = provider.offers;

          return RefreshIndicator(
            onRefresh: provider.refreshOffers,
            color: AppColors.deepCharcoal,
            backgroundColor: AppColors.curry,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                  provider.loadMoreOffers();
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      offerCount: offers.length,
                      onSearchTap: onSearchTap,
                    ),
                  ),
                  if (provider.error != null && offers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Something went wrong',
                        message: provider.error!,
                        onRetry: provider.refreshOffers,
                      ),
                    )
                  else if (provider.isLoading && offers.isEmpty)
                    const SliverToBoxAdapter(child: OfferShimmerList())
                  else if (offers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.no_food_rounded,
                        title: 'No offers yet',
                        message: 'Fresh deals will appear here soon.',
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: offers.length + (provider.isLoadingMore ? 1 : 0),
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
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
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
                color: AppColors.cream,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
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
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.curry,
                    ),
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
