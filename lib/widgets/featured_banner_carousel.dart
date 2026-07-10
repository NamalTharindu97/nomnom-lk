import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_config.dart';
import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/banner.dart';
import '../providers/banner_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class FeaturedBannerCarousel extends StatefulWidget {
  const FeaturedBannerCarousel({super.key});

  @override
  State<FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<FeaturedBannerCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final banners = context.read<BannerProvider>().banners;
      if (banners.length < 2) return;
      final next = (_currentPage + 1) % banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
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
        Navigator.of(context).pushNamed(
          AppRoutes.restaurantDetail,
          arguments: banner.linkValue,
        );
      case 'external':
        final uri = Uri.tryParse(banner.linkValue);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BannerProvider, List<FeaturedBanner>>(
      selector: (_, p) => p.banners,
      shouldRebuild: (prev, next) => prev != next,
      builder: (_, banners, __) {
        if (banners.isEmpty) return const SizedBox.shrink();

        final textTheme = Theme.of(context).textTheme;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.curry),
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
            SizedBox(
              height: 200,
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
            const SizedBox(height: 8),
            if (banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.curry
                          : context.colors.textPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
          ],
        );
      },
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
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
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                              AppLocalizations.of(context)!.sponsoredBy(banner.sponsorName!),
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
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
