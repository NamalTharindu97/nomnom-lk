import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 40 : 56,
          height: compact ? 40 : 56,
          decoration: BoxDecoration(
            color: AppColors.curry,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.curry.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: context.colors.background,
            size: compact ? 22 : 30,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context)!.appName,
          style: (compact ? textTheme.titleLarge : textTheme.headlineMedium)
              ?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
