import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class FollowSection extends StatelessWidget {
  final String? instagramUrl;
  final String? facebookUrl;
  final String? websiteUrl;

  const FollowSection({
    super.key,
    this.instagramUrl,
    this.facebookUrl,
    this.websiteUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = instagramUrl != null || facebookUrl != null || websiteUrl != null;
    if (!hasAny) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.offerFollow,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (instagramUrl != null)
              _BrandSocialButton(
                icon: Icons.camera_alt_rounded,
                label: t.offerVisitInstagram,
                color: const Color(0xFFE4405F),
                url: instagramUrl!,
              ),
            if (facebookUrl != null)
              _BrandSocialButton(
                icon: Icons.facebook_rounded,
                label: t.offerVisitFacebook,
                color: const Color(0xFF1877F2),
                url: facebookUrl!,
              ),
            if (websiteUrl != null)
              _BrandSocialButton(
                icon: Icons.language_rounded,
                label: t.offerVisitWebsite,
                color: AppColors.curry,
                url: websiteUrl!,
              ),
          ],
        ),
      ],
    );
  }
}

class _BrandSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;

  const _BrandSocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
      ],
    );
  }
}
