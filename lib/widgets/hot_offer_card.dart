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
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.offerDetails,
          arguments: offer.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: OfferImage(
                    imageUrl: offer.primaryImage,
                    borderRadius: BorderRadius.zero,
                    height: double.infinity,
                    heroTag: 'hot-offer-image-${offer.id}',
                  ),
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
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.sm + 2, Spacings.sm - 2,
                Spacings.sm + 2, Spacings.sm - 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.localizedTitle(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    CurrencyFormatter.lkr(offer.offerPrice),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.curry,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
