import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../providers/offer_provider.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';
import '../widgets/stagger_item.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacings.md, 18, Spacings.md, Spacings.sm),
              child: Text(
                'Favorites',
                style: textTheme.headlineSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Consumer<OfferProvider>(
                builder: (context, provider, child) {
                  if (!provider.hasLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final offers = provider.favoriteOffers;

                  if (offers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No saved deals',
                      message: 'Tap the heart on any deal to save it here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: Spacings.xxs, bottom: Spacings.md),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return StaggerItem(
                        index: index,
                        child: OfferCard(offer: offers[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
