import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../utils/spacings.dart';

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.xs, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.curry,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
