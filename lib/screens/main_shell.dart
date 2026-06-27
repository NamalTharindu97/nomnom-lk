import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
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
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _selectTab,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department_outlined),
              activeIcon: Icon(Icons.local_fire_department_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationProvider>(
                builder: (_, provider, __) {
                  if (provider.unreadCount > 0) {
                    return Badge(
                      label: Text('${provider.unreadCount}'),
                      child: const Icon(Icons.notifications_outlined),
                    );
                  }
                  return const Icon(Icons.notifications_outlined);
                },
              ),
              activeIcon: Consumer<NotificationProvider>(
                builder: (_, provider, __) {
                  if (provider.unreadCount > 0) {
                    return Badge(
                      label: Text('${provider.unreadCount}'),
                      child: const Icon(Icons.notifications_rounded),
                    );
                  }
                  return const Icon(Icons.notifications_rounded);
                },
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          selectedItemColor: AppColors.curry,
        ),
      ),
    );
  }
}
