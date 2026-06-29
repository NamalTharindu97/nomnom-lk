import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../providers/offer_provider.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.offerId,
    this.showLabel = false,
  });

  final String offerId;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Selector<OfferProvider, bool>(
      selector: (_, provider) => provider.offerById(offerId)?.isFavorite ?? false,
      builder: (context, isFavorite, child) {
        final icon = AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFavorite),
            color: isFavorite ? AppColors.chili : null,
          ),
        );

        if (showLabel) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.read<OfferProvider>().toggleFavorite(offerId),
              icon: icon,
              label: Text(isFavorite ? 'Saved to favorites' : 'Add to favorites'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFavorite ? AppColors.chili : AppColors.curry,
                foregroundColor:
                    isFavorite ? context.colors.textPrimary : context.colors.background,
              ),
            ),
          );
        }

        return IconButton.filledTonal(
          onPressed: () => context.read<OfferProvider>().toggleFavorite(offerId),
          tooltip: isFavorite ? 'Remove favorite' : 'Save favorite',
          icon: icon,
          style: IconButton.styleFrom(
            backgroundColor: context.colors.background.withValues(alpha: 0.78),
            foregroundColor: isFavorite ? AppColors.chili : context.colors.textPrimary,
          ),
        );
      },
    );
  }
}
