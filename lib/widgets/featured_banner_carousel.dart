import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_config.dart';
import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/context_colors.dart';
import '../models/banner.dart';
import '../providers/banner_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class FeaturedBannerCarousel extends StatefulWidget {
  const FeaturedBannerCarousel({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<FeaturedBannerCarousel>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduceMotion(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAutoScroll();
    });
  }

  @override
  void didUpdateWidget(covariant FeaturedBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _updateAutoScroll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _updateAutoScroll();
  }

  bool get _canAutoScroll =>
      widget.isActive &&
      !_reduceMotion &&
      _lifecycleState == AppLifecycleState.resumed;

  void _updateAutoScroll() {
    if (_canAutoScroll) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final banners = context.read<BannerProvider>().banners;
      if (!_canAutoScroll ||
          banners.length < 2 ||
          !_pageController.hasClients) {
        return;
      }
      final next = (_currentPage + 1) % banners.length;
      _pageController.animateToPage(
        next,
        duration: AppMotion.medium,
        curve: AppMotion.standardCurve,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onBannerTap(FeaturedBanner banner) async {
    context.read<BannerProvider>().trackClick(banner.id);

    switch (banner.linkType) {
      case 'offer':
        if (!context.mounted) return;
        Navigator.of(context).pushNamed(
          AppRoutes.offerDetails,
          arguments: banner.linkValue,
        );
      case 'restaurant':
        if (!context.mounted) return;
        Navigator.of(context).pushNamed(AppRoutes.restaurants);
      case 'external':
        final uri = Uri.tryParse(banner.linkValue);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BannerProvider,
        ({List<FeaturedBanner> banners, bool isLoading})>(
      selector: (_, p) => (banners: p.banners, isLoading: p.isLoading),
      shouldRebuild: (prev, next) => prev != next,
      builder: (_, state, __) {
        final banners = state.banners;
        if (banners.isEmpty) {
          _currentPage = 0;
          return state.isLoading
              ? const _FeaturedBannerSkeleton()
              : const SizedBox.shrink();
        }

        if (_currentPage >= banners.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _currentPage = 0;
            if (_pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
            setState(() {});
          });
        }

        final textTheme = Theme.of(context).textTheme;

        return LayoutBuilder(
          builder: (context, constraints) {
            final carouselWidth = constraints.maxWidth.clamp(0.0, 600.0);
            return Center(
              child: SizedBox(
                width: carouselWidth,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.curry),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.featuredLabel,
                            style: textTheme.labelLarge?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AspectRatio(
                        aspectRatio: 1024 / 360,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification &&
                                notification.dragDetails != null) {
                              _autoScrollTimer?.cancel();
                            } else if (notification is ScrollEndNotification) {
                              _updateAutoScroll();
                            }
                            return false;
                          },
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemCount: banners.length,
                            itemBuilder: (context, index) {
                              final banner = banners[index];
                              return _BannerTile(
                                banner: banner,
                                onTap: () => _onBannerTap(banner),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (banners.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          banners.length,
                          (index) => AnimatedContainer(
                            duration:
                                AppMotion.duration(context, AppMotion.medium),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.curry
                                  : context.colors.textPrimary
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeaturedBannerSkeleton extends StatelessWidget {
  const _FeaturedBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 14,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1024 / 360,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
    if (AppMotion.reduceMotion(context)) return content;
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceAlt,
      child: content,
    );
  }
}

class _BannerTile extends StatefulWidget {
  final FeaturedBanner banner;
  final VoidCallback onTap;

  const _BannerTile({required this.banner, required this.onTap});

  @override
  State<_BannerTile> createState() => _BannerTileState();
}

class _BannerTileState extends State<_BannerTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final banner = widget.banner;
    final reduceMotion = AppMotion.reduceMotion(context);

    return Semantics(
      button: true,
      label: banner.title ?? banner.sponsorName,
      child: GestureDetector(
        onTapDown: (_) {
          if (!reduceMotion) setState(() => _scale = 0.97);
        },
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: () {
          if (!reduceMotion) HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _scale,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standardCurve,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: ApiConfig.resolveUrl(banner.image),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.colors.surfaceAlt,
                    child: Center(
                      child: reduceMotion
                          ? const Icon(Icons.image_outlined)
                          : const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.colors.surfaceAlt,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: context.colors.muted,
                      size: 32,
                    ),
                  ),
                ),
                if (banner.title != null || banner.sponsorName != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (banner.title != null)
                            Text(
                              banner.title!,
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (banner.sponsorName != null)
                            Text(
                              banner.sponsorName!,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
