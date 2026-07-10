import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../utils/currency_formatter.dart';
import '../utils/spacings.dart';
import 'discount_badge.dart';
import 'favorite_button.dart';
import 'offer_image.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
  });

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacings.md, 0, Spacings.md, Spacings.md),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
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
                            offer.localizedTitle(locale),
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
                          size: 18,
                        ),
                        const SizedBox(width: Spacings.xxs),
                        Expanded(
                          child: Text(
                            offer.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.lkr(offer.originalPrice),
                          style: textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: context.colors.muted,
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
  }
}


