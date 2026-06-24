import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/offer_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';

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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Text(
                'Favorites',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.cream,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Consumer<OfferProvider>(
                builder: (context, provider, child) {
                  final offers = provider.favoriteOffers;

                  if (offers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No saved deals',
                      message: 'Tap the heart on any offer to keep it here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return OfferCard(offer: offers[index]);
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
