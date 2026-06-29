import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../providers/notification_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
import '../services/api_client.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
    if (_selectedIndex == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().loadNotifications();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<OfferProvider>().refreshOffers();
      context.read<RestaurantProvider>().loadRestaurants();
      context.read<ApiClient>().invalidateCache('/notifications');
      context.read<NotificationProvider>().loadNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    if (index == 3) {
      context.read<ApiClient>().invalidateCache('/notifications');
      context.read<NotificationProvider>().loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onSearchTap: () => _selectTab(1)),
      const SearchScreen(),
      const FavoritesScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.colors.surfaceAlt.withValues(alpha: 0.5)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _selectTab,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _NavIcon(
                isSelected: _selectedIndex == 0,
                icon: Icons.local_fire_department_outlined,
                activeIcon: Icons.local_fire_department_rounded,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                isSelected: _selectedIndex == 1,
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                isSelected: _selectedIndex == 2,
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
              ),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                isSelected: _selectedIndex == 3,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                badge: context.watch<NotificationProvider>().unreadCount,
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                isSelected: _selectedIndex == 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
              label: 'Profile',
            ),
          ],
          selectedItemColor: AppColors.curry,
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.isSelected,
    required this.icon,
    required this.activeIcon,
    this.badge,
  });

  final bool isSelected;
  final IconData icon;
  final IconData activeIcon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.elasticOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: badge != null && badge! > 0
          ? Badge(
              key: ValueKey('nav-badge-$isSelected'),
              label: Text('$badge'),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey('nav-icon-$isSelected'),
              ),
            )
          : Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey('nav-icon-$isSelected'),
            ),
    );
  }
}
