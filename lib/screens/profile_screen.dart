import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/offer_provider.dart';
import '../widgets/app_logo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user ?? AppUser.guest();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const AppLogo(compact: true),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.curry,
                        child: Text(
                          user.name.isEmpty
                              ? '?'
                              : user.name.substring(0, 1).toUpperCase(),
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.deepCharcoal,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.cream,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isGuest ? 'Guest mode' : user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Selector<OfferProvider, int>(
                  selector: (_, provider) => provider.favoriteOffers.length,
                  builder: (context, favoriteCount, child) {
                    return _ProfileTile(
                      icon: Icons.favorite_rounded,
                      title: 'Saved deals',
                      value: '$favoriteCount favorites',
                    );
                  },
                ),
                const SizedBox(height: 10),
                const _ProfileTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Theme',
                  value: 'Dark mode',
                ),
                const SizedBox(height: 10),
                const _ProfileTile(
                  icon: Icons.api_rounded,
                  title: 'Backend',
                  value: 'Mock data service',
                ),
                const SizedBox(height: 26),
                OutlinedButton.icon(
                  onPressed:
                      authProvider.isLoading ? null : () => _signOut(context),
                  icon: authProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(user.isGuest ? 'Leave guest mode' : 'Sign out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ocean),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.cream,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
