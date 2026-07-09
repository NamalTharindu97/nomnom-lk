class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const home = '/home';
  static const offerDetails = '/offer-details';
  static const restaurants = '/restaurants';

  static const offerDetail = '/offer';
  static const restaurantDetail = '/restaurant';
  static const editProfile = '/edit-profile';
  static const notificationPrefs = '/notification-prefs';

  static String offerDetailPath(String id) => '$offerDetail/$id';
  static String restaurantDetailPath(String id) => '$restaurantDetail/$id';
}
