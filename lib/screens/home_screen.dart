import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/featured_banner_carousel.dart';
import '../widgets/hot_offer_card.dart';
import '../widgets/offer_card.dart';
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
              const SliverToBoxAdapter(child: FeaturedBannerCarousel()),
              const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),
              const SliverToBoxAdapter(child: _HotOffersSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),
              SliverToBoxAdapter(child: _CuisineFilterChips()),
              SliverToBoxAdapter(child: _AllOffersHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: Spacings.xs)),
              _HomeBody(),
            ],
          ),
        ),
      ),
    );
  }
}

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
          final loc = AppLocalizations.of(context)!;
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: loc.generalError,
              message: _resolveError(state.error!, loc),
              onRetry: context.read<OfferProvider>().refreshOffers,
            ),
          );
        }

        if (state.isLoading && offers.isEmpty) {
          return const SliverToBoxAdapter(child: OfferShimmerList());
        }

        if (offers.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.no_food_rounded,
              title: AppLocalizations.of(context)!.homeNoDeals,
              message: AppLocalizations.of(context)!.homeNoDealsSubtitle,
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
                  key: ValueKey(offers[index].id),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BodyState &&
          error == other.error &&
          isLoading == other.isLoading &&
          isLoadingMore == other.isLoadingMore &&
          listEquals(offers, other.offers);

  @override
  int get hashCode => Object.hash(error, isLoading, isLoadingMore, Object.hashAll(offers));
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
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacings.md, 18, Spacings.md, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppLogo(compact: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.xs, vertical: Spacings.xs),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.homeDealCount(offerCount),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.curry,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              t.homeBestDeals,
              style: textTheme.headlineSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.homeBestDealsSubtitle,
              style: textTheme.bodyMedium?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const ValueKey('home-search-bar'),
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.sm + 2, vertical: Spacings.sm + 2),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.homeSearchHint,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.colors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.curry, size: 18),
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

class _AllOffersHeader extends StatelessWidget {
  const _AllOffersHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacings.md, Spacings.xs, Spacings.md, 0),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.allLabel,
            style: textTheme.titleSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Divider(
              thickness: 1,
              color: context.colors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: context.colors.textPrimary.withValues(alpha: 0.08),
    );
  }
}

class _HotOffersSection extends StatelessWidget {
  const _HotOffersSection();

  static const _cardScale = 0.52;
  static const _cardAspect = 9 / 16;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;

    return Selector<OfferProvider, _HotState>(
      selector: (_, p) => _HotState(
        offers: p.hotOffers,
        isLoading: p.isLoading && !p.hasLoaded,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (_, state, __) {
        if (state.isLoading) {
          return _buildLoading(context);
        }

        final hotOffers = state.offers;
        if (hotOffers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: Spacings.md, bottom: Spacings.sm, right: Spacings.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                    color: AppColors.chili, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.homeHotOffers,
                    style: textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _cardHeight(context),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
                itemCount: hotOffers.length + _endPad(hotOffers.length),
                itemBuilder: (context, index) {
                  if (index >= hotOffers.length) {
                    return const SizedBox(width: Spacings.md);
                  }
                  final offer = hotOffers[index];
                  return SizedBox(
                    width: _cardWidth(context),
                    child: HotOfferCard(offer: offer, locale: locale),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    final height = _cardHeight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacings.md, bottom: Spacings.sm),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                color: AppColors.chili, size: 18),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.homeHotOffers,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
            itemCount: 3,
            itemBuilder: (_, __) => HotOfferShimmer(
              width: _cardWidth(context),
              height: height,
            ),
          ),
        ),
      ],
    );
  }

  double _cardWidth(BuildContext context) =>
      MediaQuery.of(context).size.width * _cardScale;

  double _cardHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final labelSize = theme.labelLarge?.fontSize ?? 14;
    final labelLineHeight = labelSize * 1.6;
    final padding = (Spacings.sm - 2) * 2;
    return _cardWidth(context) * _cardAspect + padding + labelLineHeight + 4;
  }

  int _endPad(int count) => count > 1 ? 1 : 0;
}

class _HotState {
  final List<Offer> offers;
  final bool isLoading;

  const _HotState({required this.offers, required this.isLoading});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HotState &&
          isLoading == other.isLoading &&
          listEquals(offers, other.offers);

  @override
  int get hashCode => Object.hash(isLoading, Object.hashAll(offers));
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
          padding: const EdgeInsets.fromLTRB(
            Spacings.md, Spacings.sm, Spacings.md, Spacings.sm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: AppLocalizations.of(context)!.allLabel,
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

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm + 2, vertical: Spacings.xs),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.curry : context.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: widget.isSelected
                ? null
                : Border.all(color: context.colors.textPrimary.withValues(alpha: 0.08)),
          ),
          child: Text(
            widget.label,
            style: textTheme.labelMedium?.copyWith(
              color: widget.isSelected ? context.colors.background : context.colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
