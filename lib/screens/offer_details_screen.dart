import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/api_offer_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/offer_image.dart';

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
      final client = ApiClient();
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
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _fetchedOffer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: AppLocalizations.of(context)!.offerNotFound,
          message: _error ?? AppLocalizations.of(context)!.offerNotFoundSubtitle,
        ),
      );
    }

    return _OfferDetailsContent(offer: _fetchedOffer!);
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          offer.restaurantName,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacings.lg, Spacings.xl, Spacings.lg, Spacings.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StaggeredFadeSlide(
                animation: _animation,
                index: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        offer.localizedTitle(Localizations.localeOf(context).languageCode),
                        style: textTheme.headlineSmall?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DiscountPill(label: offer.discountLabelLocalized(Localizations.localeOf(context).languageCode)),
                  ],
                ),
              ),
              const SizedBox(height: Spacings.xl),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 1,
                child: Text(
                  offer.localizedDescription(Localizations.localeOf(context).languageCode),
                  style: textTheme.bodyLarge?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: Spacings.xl),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 2,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: OfferImage(
                    imageUrl: offer.primaryImage,
                    heroTag: 'offer-image-${offer.id}',
                  ),
                ),
              ),
              const SizedBox(height: Spacings.xl),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 3,
                child: _PricePanel(offer: offer),
              ),
              const SizedBox(height: Spacings.xl),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 4,
                child: _InfoRow(
                  icon: Icons.storefront_rounded,
                  title: AppLocalizations.of(context)!.offerRestaurantLabel,
                  value: offer.restaurantName,
                ),
              ),
              const SizedBox(height: 12),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 5,
                child: _InfoRow(
                  icon: Icons.location_on_rounded,
                  title: AppLocalizations.of(context)!.offerLocation,
                  value: offer.location,
                ),
              ),
              const SizedBox(height: 12),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 6,
                child: _InfoRow(
                  icon: Icons.local_offer_rounded,
                  title: AppLocalizations.of(context)!.offerDiscountLabel,
                  value: offer.discountLabelLocalized(Localizations.localeOf(context).languageCode),
                ),
              ),
              const SizedBox(height: Spacings.xxl),
              _StaggeredFadeSlide(
                animation: _animation,
                index: 7,
                child: FavoriteButton(offerId: offer.id, showLabel: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.offerDealPriceLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.lkr(offer.offerPrice),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.curry,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.lkr(offer.originalPrice),
                style: textTheme.bodyLarge?.copyWith(
                  color: context.colors.muted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: context.colors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.offerSaveAmount(CurrencyFormatter.lkr(offer.saving)),
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ocean),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.xs, vertical: Spacings.xs),
      decoration: BoxDecoration(
        color: AppColors.curry,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.colors.background,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
