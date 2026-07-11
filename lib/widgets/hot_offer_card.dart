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

class HotOfferCard extends StatelessWidget {
  const HotOfferCard({
    super.key,
    required this.offer,
    required this.locale,
  });

  final Offer offer;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.offerDetails,
          arguments: offer.id,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OfferImage(
              imageUrl: offer.primaryImage,
              borderRadius: BorderRadius.zero,
              height: double.infinity,
              width: double.infinity,
              heroTag: 'hot-offer-image-${offer.id}',
            ),
            Positioned(
              top: Spacings.sm,
              left: Spacings.sm,
              child: DiscountBadge(
                label: offer.discountLabelLocalized(locale),
              ),
            ),
            Positioned(
              top: 8,
              right: Spacings.xs,
              child: FavoriteButton(offerId: offer.id),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.localizedTitle(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.lkr(offer.offerPrice),
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.curry,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.curry.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.savings_rounded,
                                size: 10,
                                color: AppColors.curry,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Save ${CurrencyFormatter.lkr(offer.saving)}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.curry,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
