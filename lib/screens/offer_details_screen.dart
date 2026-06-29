import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../providers/offer_provider.dart';
import '../services/api_client.dart';
import '../services/api_offer_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/offer_image.dart';

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
          _error = 'Could not load offer details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _fetchedOffer == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Offer not found',
          message: _error ?? 'This deal may have been removed.',
        ),
      );
    }

    return _OfferDetailsContent(offer: _fetchedOffer!);
  }
}

class _OfferDetailsContent extends StatelessWidget {
  const _OfferDetailsContent({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            stretch: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Spacings.xs),
                child: FavoriteButton(offerId: offer.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: OfferImage(
                imageUrl: offer.primaryImage,
                heroTag: 'offer-image-${offer.id}',
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacings.lg, 22, Spacings.lg, Spacings.xl + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.title,
                              style: textTheme.headlineSmall?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer.restaurantName,
                              style: textTheme.titleMedium?.copyWith(
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _DiscountPill(label: offer.discountLabel),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PricePanel(offer: offer),
                  const SizedBox(height: 22),
                  Text(
                    offer.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _InfoRow(
                    icon: Icons.storefront_rounded,
                    title: 'Restaurant',
                    value: offer.restaurantName,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    value: offer.location,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.local_offer_rounded,
                    title: 'Discount',
                    value: offer.discountLabel,
                  ),
                  const SizedBox(height: 28),
                  FavoriteButton(offerId: offer.id, showLabel: true),
                ],
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deal price',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.muted,
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
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Save ${CurrencyFormatter.lkr(offer.saving)}',
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
      padding: const EdgeInsets.all(Spacings.sm + 2),
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
                    color: AppColors.muted,
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
