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
        const SizedBox(height: 4),
        Text(
          t.offerFollowHint,
          style: textTheme.labelMedium?.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: 12),
        if (instagramUrl != null)
          _SocialPillButton(
            icon: Icons.camera_alt_rounded,
            label: t.offerVisitInstagram,
            color: const Color(0xFFE4405F),
            url: instagramUrl!,
          ),
        if (instagramUrl != null && facebookUrl != null)
          const SizedBox(height: 8),
        if (facebookUrl != null)
          _SocialPillButton(
            icon: Icons.facebook_rounded,
            label: t.offerVisitFacebook,
            color: const Color(0xFF1877F2),
            url: facebookUrl!,
          ),
        if (facebookUrl != null && websiteUrl != null)
          const SizedBox(height: 8),
        if (websiteUrl != null)
          _SocialPillButton(
            icon: Icons.language_rounded,
            label: t.offerVisitWebsite,
            color: AppColors.curry,
            url: websiteUrl!,
          ),
      ],
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;

  const _SocialPillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
