import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import '../providers/platform_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/api_offer_service.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/follow_section.dart';
import '../widgets/info_card.dart';
import '../widgets/offer_image.dart';
import '../widgets/order_buttons.dart';
import '../widgets/price_panel.dart';

class _StaggeredFadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double delay = (index * 0.08).clamp(0.0, 1.0);
    final double start = delay;
    final double end = (delay + 0.4).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }
}

class OfferDetailsScreen extends StatefulWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offerId,
  });

  final String offerId;

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  Offer? _fetchedOffer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final localOffer = context.read<OfferProvider>().offerById(widget.offerId);
    if (localOffer != null) {
      setState(() {
        _fetchedOffer = localOffer;
        _isLoading = false;
      });
      return;
    }

    try {
      final client = context.read<ApiClient>();
      final service = ApiOfferService(client);
      final offer = await service.getOffer(widget.offerId);
      if (mounted) {
        setState(() {
          _fetchedOffer = offer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.offerDetailsError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _OfferDetailsSkeleton();
    }

    if (_error != null || _fetchedOffer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: AppLocalizations.of(context)!.offerNotFound,
          message:
              _error ?? AppLocalizations.of(context)!.offerNotFoundSubtitle,
        ),
      );
    }

    return _OfferDetailsContent(offer: _fetchedOffer!);
  }
}

class _OfferDetailsSkeleton extends StatelessWidget {
  const _OfferDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBlock(width: 220, height: 28),
                    SizedBox(height: Spacings.sm),
                    _ShimmerBlock(width: 120, height: 18),
                    SizedBox(height: Spacings.xl),
                    _ShimmerBlock(width: double.infinity, height: 72),
                    SizedBox(height: Spacings.xl),
                    AspectRatio(
                      aspectRatio: 1,
                      child: _ShimmerBlock(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    SizedBox(height: Spacings.xl),
                    _ShimmerBlock(width: double.infinity, height: 112),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferDetailsContent extends StatefulWidget {
  final Offer offer;

  const _OfferDetailsContent({required this.offer});

  @override
  State<_OfferDetailsContent> createState() => _OfferDetailsContentState();
}

class _OfferDetailsContentState extends State<_OfferDetailsContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.medium,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final offer = widget.offer;
    final hasOrderPlatforms = offer.orderPlatforms.isNotEmpty;
    final hasSocialLinks = offer.socialLinks.isNotEmpty;
    final t = AppLocalizations.of(context)!;
    final platformProvider = context.watch<PlatformProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          offer.restaurantName,
          style: textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
                  Spacings.xl,
                  constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
                  Spacings.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 0,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Spacings.sm,
                        runSpacing: Spacings.sm,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth < 600
                                  ? constraints.maxWidth -
                                      (constraints.maxWidth < 360
                                          ? Spacings.md * 2
                                          : Spacings.lg * 2)
                                  : 440,
                            ),
                            child: Text(
                              offer.localizedTitle(
                                Localizations.localeOf(context).languageCode,
                              ),
                              style: textTheme.headlineSmall?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _DiscountPill(
                            label: offer.discountLabelLocalized(
                              Localizations.localeOf(context).languageCode,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacings.xl),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 1,
                      child: Text(
                        offer.localizedDescription(
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: textTheme.bodyLarge?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacings.xl),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 2,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: OfferImage(
                          imageUrl: offer.primaryImage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacings.xl),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 3,
                      child: PricePanel(offer: offer),
                    ),
                    const SizedBox(height: Spacings.xl),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 4,
                      child: _SectionHeader(
                        icon: Icons.info_outline_rounded,
                        title: t.offerDetailsLabel,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 5,
                      child: InfoCard(
                        icon: Icons.storefront_rounded,
                        title: t.offerRestaurantLabel,
                        value: offer.restaurantName,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 6,
                      child: InfoCard(
                        icon: Icons.local_offer_rounded,
                        title: t.offerDiscountLabel,
                        value: offer.discountLabelLocalized(
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ),
                    if (hasOrderPlatforms) ...[
                      const SizedBox(height: Spacings.xl),
                      _StaggeredFadeSlide(
                        animation: _animation,
                        index: 8,
                        child: platformProvider.isLoading
                            ? _OrderButtonsShimmer()
                            : OrderButtonsSection(
                                platforms: platformProvider.orderPlatforms
                                    .where((p) =>
                                        offer.orderPlatforms.contains(p.slug))
                                    .toList(),
                              ),
                      ),
                    ],
                    if (hasSocialLinks) ...[
                      const SizedBox(height: Spacings.xl),
                      _StaggeredFadeSlide(
                        animation: _animation,
                        index: 9,
                        child: platformProvider.isLoading
                            ? _SocialSectionShimmer()
                            : FollowSection(
                                socialLinks: offer.socialLinks,
                                platforms: platformProvider.socialPlatforms,
                              ),
                      ),
                    ],
                    const SizedBox(height: Spacings.xl),
                    _StaggeredFadeSlide(
                      animation: _animation,
                      index: 10,
                      child: FavoriteButton(offerId: offer.id, showLabel: true),
                    ),
                    const SizedBox(height: Spacings.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.curry),
        const SizedBox(width: Spacings.xs),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String label;

  const _DiscountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.curry,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.curry.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.colors.background
                  : Colors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _OrderButtonsShimmer extends StatelessWidget {
  const _OrderButtonsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart_rounded, size: 18, color: AppColors.curry),
            const SizedBox(width: Spacings.xs),
            _ShimmerBlock(width: 100, height: 18),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        _motionShimmer(
          context,
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: Spacings.xs),
        _motionShimmer(
          context,
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialSectionShimmer extends StatelessWidget {
  const _SocialSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.share_rounded, size: 18, color: AppColors.curry),
            const SizedBox(width: Spacings.xs),
            _ShimmerBlock(width: 80, height: 18),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        _motionShimmer(
          context,
          Row(
            children: List.generate(
              3,
              (_) => Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: Spacings.sm),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    if (AppMotion.reduceMotion(context)) return block;
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceAlt,
      child: block,
    );
  }
}

Widget _motionShimmer(BuildContext context, Widget child) {
  if (AppMotion.reduceMotion(context)) return child;
  return Shimmer.fromColors(
    baseColor: context.colors.surface,
    highlightColor: context.colors.surfaceAlt,
    child: child,
  );
}
