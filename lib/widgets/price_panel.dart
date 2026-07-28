import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/offer.dart';
import '../utils/currency_formatter.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class PricePanel extends StatelessWidget {
  final Offer offer;

  const PricePanel({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final daysUntilEnd = offer.endDate.difference(now).inDays;
    final priceDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.offerDealPriceLabel,
          style: textTheme.labelLarge?.copyWith(
            color: context.colors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              CurrencyFormatter.lkr(offer.offerPrice),
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.curry,
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                CurrencyFormatter.lkr(offer.originalPrice),
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colors.muted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: context.colors.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            color: AppColors.curry,
          ),
          LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: const EdgeInsets.all(16),
              child: Flex(
                direction: constraints.maxWidth < 430
                    ? Axis.vertical
                    : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (constraints.maxWidth < 430)
                    priceDetails
                  else
                    Flexible(fit: FlexFit.loose, child: priceDetails),
                  if (constraints.maxWidth < 430)
                    const SizedBox(height: 12)
                  else
                    const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.offerSaveAmount(CurrencyFormatter.lkr(offer.saving)),
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (daysUntilEnd >= 0 && daysUntilEnd <= 7)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.chili.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.chili),
                  const SizedBox(width: 6),
                  Text(
                    daysUntilEnd == 0
                        ? t.offerEndsToday
                        : t.offerEndsIn(daysUntilEnd.toString()),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.chili,
                      fontWeight: FontWeight.w700,
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
