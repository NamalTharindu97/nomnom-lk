import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/social_link.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class FollowSection extends StatelessWidget {
  final List<SocialLink> socialLinks;

  const FollowSection({
    super.key,
    this.socialLinks = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.offerFollow,
          style: textTheme.titleMedium?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          t.offerFollowHint,
          style: textTheme.labelMedium?.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < socialLinks.length; i++) ...[
          _SocialPillButton(
            icon: _iconForPlatform(socialLinks[i].platform),
            label: _labelForPlatform(socialLinks[i].platform, t),
            color: _colorForPlatform(socialLinks[i].platform),
            url: socialLinks[i].url,
          ),
          if (i < socialLinks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  static IconData _iconForPlatform(String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'website':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  static String _labelForPlatform(String platform, AppLocalizations t) {
    switch (platform) {
      case 'instagram':
        return t.offerVisitInstagram;
      case 'facebook':
        return t.offerVisitFacebook;
      case 'website':
        return t.offerVisitWebsite;
      default:
        return t.offerVisitWebsite;
    }
  }

  static Color _colorForPlatform(String platform) {
    switch (platform) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'website':
        return AppColors.curry;
      default:
        return AppColors.curry;
    }
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
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
