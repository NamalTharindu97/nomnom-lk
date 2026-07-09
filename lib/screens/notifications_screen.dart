import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/stagger_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.notificationsTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      if (provider.notifications.isEmpty) return const SizedBox();
                      return TextButton(
                        onPressed: () => provider.markAllAsRead(),
                        child: Text(AppLocalizations.of(context)!.notificationsMarkAllRead),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (provider.error != null) {
                    return EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: AppLocalizations.of(context)!.generalFailedToLoad,
                      message: provider.error!,
                    );
                  }

                  final notifications = provider.notifications;
                  if (notifications.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: AppLocalizations.of(context)!.notificationsEmpty,
                      message: AppLocalizations.of(context)!.notificationsAllCaughtUp,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return StaggerItem(
                        index: index,
                        child: _NotificationTile(
                          notification: n,
                          onTap: () {
                            provider.markAsRead(n.id);
                            if (n.offerId != null && n.offerId!.isNotEmpty) {
                              Navigator.of(context).pushNamed(
                                AppRoutes.offerDetails,
                                arguments: n.offerId,
                              );
                            }
                          },
                        ),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : context.colors.surface.withValues(alpha: 0.5),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: Spacings.sm),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.transparent : AppColors.curry,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight:
                          notification.isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: Spacings.xxs),
                  Text(
                    notification.body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.colors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: context.colors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
