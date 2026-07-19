import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../utils/spacings.dart';

enum OrderPlatform {
  uberEats,
  pickMe,
}

OrderPlatform? parsePlatform(String value) {
  return switch (value) {
    'uber_eats' => OrderPlatform.uberEats,
    'pickme' => OrderPlatform.pickMe,
    _ => null,
  };
}

Color _platformColor(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => const Color(0xFF06C167),
    OrderPlatform.pickMe => const Color(0xFF00B14F),
  };
}

IconData _platformIcon(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => Icons.delivery_dining_rounded,
    OrderPlatform.pickMe => Icons.local_taxi_rounded,
  };
}

String _platformUri(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => 'ubereats://',
    OrderPlatform.pickMe => 'pickme://',
  };
}

class OrderButtonsSection extends StatelessWidget {
  final List<String> platforms;

  const OrderButtonsSection({
    super.key,
    required this.platforms,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final parsed = platforms
        .map(parsePlatform)
        .whereType<OrderPlatform>()
        .toList();

    if (parsed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart_rounded, size: 18, color: AppColors.curry),
            const SizedBox(width: Spacings.xs),
            Text(
              t.offerOrderNow,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        for (int i = 0; i < parsed.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacings.xs),
          _PlatformButton(platform: parsed[i], t: t),
        ],
      ],
    );
  }
}

class _PlatformButton extends StatelessWidget {
  final OrderPlatform platform;
  final AppLocalizations t;

  const _PlatformButton({
    required this.platform,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (platform) {
      OrderPlatform.uberEats => t.offerOrderUberEats,
      OrderPlatform.pickMe => t.offerOrderPickMe,
    };
    final brandColor = _platformColor(platform);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: brandColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final uri = Uri.parse(_platformUri(platform));
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.offerNoAppFound)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(_platformIcon(platform), color: Colors.white, size: 22),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
