// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NomNom LK';

  @override
  String get splashTagline => 'Discover Sri Lanka\'s Best Food Deals';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSignInButton => 'Sign In';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegisterLink => 'Register';

  @override
  String get loginErrorGeneric => 'Sign in failed. Please try again.';

  @override
  String get loginErrorInvalidCredentials => 'Invalid email or password';

  @override
  String get loginSigningIn => 'Signing in...';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginContinueWithEmail => 'Continue with email';

  @override
  String get loginEmailHint => 'Enter your email';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginPasswordMinChars => 'At least 8 characters';

  @override
  String get loginErrorSuspended => 'Your account has been suspended.';

  @override
  String get loginErrorGoogleEmail => 'This email uses Google Sign-In.';

  @override
  String get loginEmailVerificationRequired => 'Please verify your email first';

  @override
  String get loginResend => 'Resend';

  @override
  String get homeHotOffers => 'Hot Offers';

  @override
  String get homeBestDeals => 'Best deals near you';

  @override
  String get homeBestDealsSubtitle => 'Discover the best food deals from your favorite local spots.';

  @override
  String get homeNoDeals => 'No deals yet';

  @override
  String get homeNoDealsSubtitle => 'Check back for new offers from your favorite eateries.';

  @override
  String get homeRestaurants => 'Restaurants';

  @override
  String get homeSearchHint => 'Search kottu, hoppers, restaurants...';

  @override
  String homeDealCount(int count) {
    return '$count deals';
  }

  @override
  String get searchHint => 'Search for dishes, restaurants, or cuisines...';

  @override
  String get searchEmptyTitle => 'What are you craving?';

  @override
  String get searchEmptySubtitle => 'Search for dishes, restaurants, or cuisines.';

  @override
  String get searchNoResults => 'No deals found';

  @override
  String get searchNoResultsSubtitle => 'Try another dish or restaurant name.';

  @override
  String get searchRestaurantsTab => 'Restaurants';

  @override
  String get searchOffersTab => 'Offers';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get favoritesTitle => 'Your Favorites';

  @override
  String get favoritesEmpty => 'Tap the heart on any deal to save it here.';

  @override
  String get favoritesNoSavedDeals => 'No saved deals';

  @override
  String get restaurantsTitle => 'All Restaurants';

  @override
  String get restaurantsEmpty => 'No restaurants found.';

  @override
  String restaurantsTotal(int count) {
    return '$count total';
  }

  @override
  String get restaurantsFailedToLoad => 'Failed to load';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsAllCaughtUp => 'You\'re all caught up!';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navRestaurants => 'Restaurants';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String offerDiscount(int percent) {
    return '$percent% OFF';
  }

  @override
  String offerExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get offerViewDetails => 'View Details';

  @override
  String get offerDetailsTitle => 'Offer Details';

  @override
  String get offerOriginalPrice => 'Was';

  @override
  String get offerOfferPrice => 'Now';

  @override
  String get offerLocation => 'Location';

  @override
  String offerValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get offerShare => 'Share';

  @override
  String get offerDetailsError => 'Could not load offer details.';

  @override
  String get offerNotFound => 'Offer not found';

  @override
  String get offerNotFoundSubtitle => 'This deal may have been removed.';

  @override
  String get offerRestaurantLabel => 'Restaurant';

  @override
  String get offerDiscountLabel => 'Discount';

  @override
  String get offerDealPriceLabel => 'Deal price';

  @override
  String offerSaveAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get registerCreateAccount => 'Create your account';

  @override
  String get registerFullNameHint => 'Enter your name';

  @override
  String get registerFullNameLabel => 'Full name';

  @override
  String get registerEmailHint => 'Enter your email';

  @override
  String get registerEmailInvalid => 'Enter a valid email';

  @override
  String get registerEmailLabel => 'Email address';

  @override
  String get registerPasswordMinChars => 'At least 8 characters';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get registerCreatingAccount => 'Creating account...';

  @override
  String get registerCreateAccountButton => 'Create account';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account?';

  @override
  String get registerSignInLink => 'Sign In';

  @override
  String get registerErrorEmailExists => 'An account with this email already exists.';

  @override
  String get registerErrorGeneric => 'Registration failed. Try again.';

  @override
  String get verifyCheckYourEmail => 'Check your email';

  @override
  String get verifyWeSentCodeTo => 'We sent a 6-digit code to';

  @override
  String get verifyEnterCode => 'Enter the 6-digit code';

  @override
  String get verifyVerifying => 'Verifying...';

  @override
  String get verifyVerifyAndLogin => 'Verify & Login';

  @override
  String verifyResendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get verifyResendCode => 'Resend code';

  @override
  String get verifyUseDifferentEmail => 'Use a different email';

  @override
  String get verifyCodeResent => 'Code resent!';

  @override
  String get verifyErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get profileAdmin => 'Admin';

  @override
  String get profileRestaurantOwner => 'Restaurant Owner';

  @override
  String get profileFoodie => 'Foodie';

  @override
  String get profileMyFavorites => 'My Favorites';

  @override
  String get profileSavedDeals => 'Saved deals';

  @override
  String get profileBrowseRestaurants => 'Browse Restaurants';

  @override
  String get profileViewAllRestaurants => 'View all restaurants';

  @override
  String get profileAbout => 'About';

  @override
  String get profileVersion => 'Version 1.0.0';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get profileLightMode => 'Light mode';

  @override
  String get profileSaved => 'Saved';

  @override
  String get profileMemberSince => 'Member';

  @override
  String get profileNotificationPreferences => 'Notification Preferences';

  @override
  String get profileManageNotifications => 'Manage notification settings';

  @override
  String get profileShareApp => 'Share NomNom LK';

  @override
  String get profileShareAppSubtitle => 'Tell your friends';

  @override
  String get profileShareAppMessage => 'Check out NomNom LK - Sri Lanka\'s best food deals app!';

  @override
  String get profileRateApp => 'Rate the App';

  @override
  String get profileRateAppSubtitle => 'Leave a review';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update personal info';

  @override
  String get editProfileNameLabel => 'Full Name';

  @override
  String get editProfileNameRequired => 'Name is required';

  @override
  String get editProfilePhoneLabel => 'Phone Number';

  @override
  String get editProfileEmailLabel => 'Email';

  @override
  String get editProfileSave => 'Save Changes';

  @override
  String get editProfileSaved => 'Profile updated';

  @override
  String get notifPrefsTitle => 'Notification Preferences';

  @override
  String get notifPrefsNewOffers => 'New Offers';

  @override
  String get notifPrefsNewOffersDesc => 'New offers from your favorite restaurants';

  @override
  String get notifPrefsPriceDrops => 'Price Drops';

  @override
  String get notifPrefsPriceDropsDesc => 'When prices drop on saved deals';

  @override
  String get notifPrefsOpenings => 'Restaurant Openings';

  @override
  String get notifPrefsOpeningsDesc => 'New restaurants opening nearby';

  @override
  String get generalLoading => 'Loading...';

  @override
  String get generalError => 'Something went wrong';

  @override
  String get generalRetry => 'Try Again';

  @override
  String get generalNoInternet => 'No internet connection';

  @override
  String get generalGuest => 'Guest';

  @override
  String get generalLogout => 'Log Out';

  @override
  String get generalCancel => 'Cancel';

  @override
  String get generalSave => 'Save';

  @override
  String get generalDelete => 'Delete';

  @override
  String get generalConfirm => 'Confirm';

  @override
  String get generalFailedToLoad => 'Failed to load';

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get allLabel => 'All';
}
