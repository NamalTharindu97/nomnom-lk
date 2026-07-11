import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'NomNom LK'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Discover Sri Lanka\'s Daily Best Food Deals'**
  String get splashTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignInButton;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginRegisterLink;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginSigningIn;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get loginContinueWithEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailHint;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get loginPasswordMinChars;

  /// No description provided for @loginErrorSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended.'**
  String get loginErrorSuspended;

  /// No description provided for @loginErrorGoogleEmail.
  ///
  /// In en, this message translates to:
  /// **'This email uses Google Sign-In.'**
  String get loginErrorGoogleEmail;

  /// No description provided for @loginEmailVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first'**
  String get loginEmailVerificationRequired;

  /// No description provided for @loginResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get loginResend;

  /// No description provided for @homeHotOffers.
  ///
  /// In en, this message translates to:
  /// **'Hot Offers'**
  String get homeHotOffers;

  /// No description provided for @homeBestDeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deals'**
  String get homeBestDeals;

  /// No description provided for @homeBestDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh daily offers from your favorite spots'**
  String get homeBestDealsSubtitle;

  /// No description provided for @homeNoDeals.
  ///
  /// In en, this message translates to:
  /// **'No daily deals yet'**
  String get homeNoDeals;

  /// No description provided for @homeNoDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back tomorrow for fresh daily offers'**
  String get homeNoDealsSubtitle;

  /// No description provided for @homeRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get homeRestaurants;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search today\'s deals'**
  String get homeSearchHint;

  /// No description provided for @homeDealCount.
  ///
  /// In en, this message translates to:
  /// **'{count} daily deals'**
  String homeDealCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search daily deals, dishes, restaurants...'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you craving?'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search today\'s deals or your favorite restaurants'**
  String get searchEmptySubtitle;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No daily deals found'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try searching for another dish or restaurant'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchRestaurantsTab.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get searchRestaurantsTab;

  /// No description provided for @searchOffersTab.
  ///
  /// In en, this message translates to:
  /// **'Daily Offers'**
  String get searchOffersTab;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecent;

  /// No description provided for @searchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchClearAll;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any daily deal to save it here'**
  String get favoritesEmpty;

  /// No description provided for @favoritesNoSavedDeals.
  ///
  /// In en, this message translates to:
  /// **'No saved daily deals'**
  String get favoritesNoSavedDeals;

  /// No description provided for @restaurantsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Restaurants'**
  String get restaurantsTitle;

  /// No description provided for @restaurantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restaurants found.'**
  String get restaurantsEmpty;

  /// No description provided for @restaurantsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String restaurantsTotal(int count);

  /// No description provided for @restaurantsFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get restaurantsFailedToLoad;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notificationsAllCaughtUp;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get navRestaurants;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @offerDiscount.
  ///
  /// In en, this message translates to:
  /// **'{percent}% OFF'**
  String offerDiscount(int percent);

  /// No description provided for @offerExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String offerExpires(String date);

  /// No description provided for @offerViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get offerViewDetails;

  /// No description provided for @offerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Details'**
  String get offerDetailsTitle;

  /// No description provided for @offerOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'Was'**
  String get offerOriginalPrice;

  /// No description provided for @offerOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get offerOfferPrice;

  /// No description provided for @offerLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get offerLocation;

  /// No description provided for @offerValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String offerValidUntil(String date);

  /// No description provided for @offerShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get offerShare;

  /// No description provided for @offerDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load offer details.'**
  String get offerDetailsError;

  /// No description provided for @offerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Offer not found'**
  String get offerNotFound;

  /// No description provided for @offerNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This daily deal may have expired'**
  String get offerNotFoundSubtitle;

  /// No description provided for @offerRestaurantLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get offerRestaurantLabel;

  /// No description provided for @offerDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get offerDiscountLabel;

  /// No description provided for @offerDealPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s price'**
  String get offerDealPriceLabel;

  /// No description provided for @offerSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String offerSaveAmount(String amount);

  /// No description provided for @registerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerCreateAccount;

  /// No description provided for @registerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get registerFullNameHint;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullNameLabel;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get registerEmailHint;

  /// No description provided for @registerEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get registerEmailInvalid;

  /// No description provided for @registerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get registerPasswordMinChars;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordLabel;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordsDoNotMatch;

  /// No description provided for @registerCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get registerCreatingAccount;

  /// No description provided for @registerCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCreateAccountButton;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get registerSignInLink;

  /// No description provided for @registerErrorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get registerErrorEmailExists;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Try again.'**
  String get registerErrorGeneric;

  /// No description provided for @verifyCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyCheckYourEmail;

  /// No description provided for @verifyWeSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get verifyWeSentCodeTo;

  /// No description provided for @verifyEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get verifyEnterCode;

  /// No description provided for @verifyVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifyVerifying;

  /// No description provided for @verifyVerifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyVerifyAndLogin;

  /// No description provided for @verifyResendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String verifyResendCodeIn(int seconds);

  /// No description provided for @verifyResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyResendCode;

  /// No description provided for @verifyUseDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get verifyUseDifferentEmail;

  /// No description provided for @verifyCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent!'**
  String get verifyCodeResent;

  /// No description provided for @verifyErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get verifyErrorGeneric;

  /// No description provided for @profileAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileAdmin;

  /// No description provided for @profileRestaurantOwner.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Owner'**
  String get profileRestaurantOwner;

  /// No description provided for @profileFoodie.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get profileFoodie;

  /// No description provided for @profileMyFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get profileMyFavorites;

  /// No description provided for @profileSavedDeals.
  ///
  /// In en, this message translates to:
  /// **'Saved deals'**
  String get profileSavedDeals;

  /// No description provided for @profileBrowseRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Browse Restaurants'**
  String get profileBrowseRestaurants;

  /// No description provided for @profileViewAllRestaurants.
  ///
  /// In en, this message translates to:
  /// **'View all restaurants'**
  String get profileViewAllRestaurants;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get profileVersion;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get profileDarkMode;

  /// No description provided for @profileLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get profileLightMode;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get profileMemberSince;

  /// No description provided for @profileNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get profileNotificationPreferences;

  /// No description provided for @profileManageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage notification settings'**
  String get profileManageNotifications;

  /// No description provided for @profileShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share NomNom LK'**
  String get profileShareApp;

  /// No description provided for @profileShareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell your friends'**
  String get profileShareAppSubtitle;

  /// No description provided for @profileShareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out NomNom LK - Sri Lanka\'s daily food deals app!'**
  String get profileShareAppMessage;

  /// No description provided for @profileRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get profileRateApp;

  /// No description provided for @profileRateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get profileRateAppSubtitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update personal info'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get editProfileNameLabel;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get editProfileNameRequired;

  /// No description provided for @editProfilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get editProfilePhoneLabel;

  /// No description provided for @editProfileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmailLabel;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSave;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileSaved;

  /// No description provided for @notifPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notifPrefsTitle;

  /// No description provided for @notifPrefsNewOffers.
  ///
  /// In en, this message translates to:
  /// **'New Offers'**
  String get notifPrefsNewOffers;

  /// No description provided for @notifPrefsNewOffersDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily offers from your favorite restaurants'**
  String get notifPrefsNewOffersDesc;

  /// No description provided for @notifPrefsPriceDrops.
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get notifPrefsPriceDrops;

  /// No description provided for @notifPrefsPriceDropsDesc.
  ///
  /// In en, this message translates to:
  /// **'When prices drop on saved daily deals'**
  String get notifPrefsPriceDropsDesc;

  /// No description provided for @notifPrefsOpenings.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Openings'**
  String get notifPrefsOpenings;

  /// No description provided for @notifPrefsOpeningsDesc.
  ///
  /// In en, this message translates to:
  /// **'New restaurants opening nearby'**
  String get notifPrefsOpeningsDesc;

  /// No description provided for @generalLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get generalLoading;

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get generalError;

  /// No description provided for @generalRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get generalRetry;

  /// No description provided for @generalNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get generalNoInternet;

  /// No description provided for @generalGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get generalGuest;

  /// No description provided for @generalLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get generalLogout;

  /// No description provided for @generalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generalCancel;

  /// No description provided for @generalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get generalSave;

  /// No description provided for @generalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get generalDelete;

  /// No description provided for @generalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get generalConfirm;

  /// No description provided for @generalFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get generalFailedToLoad;

  /// No description provided for @favoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemove;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @editProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. Please try again.'**
  String get editProfileSaveError;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get uploadFailed;

  /// No description provided for @featuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredLabel;

  /// No description provided for @sponsoredBy.
  ///
  /// In en, this message translates to:
  /// **'Sponsored by {name}'**
  String sponsoredBy(String name);

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @offerShareText.
  ///
  /// In en, this message translates to:
  /// **'Check out this deal at {restaurant}!\n{deal} on {title}\n\n{description}\n\nDownload the app for daily food deals in Sri Lanka!'**
  String offerShareText(String restaurant, String deal, String title, String description);

  /// No description provided for @generalSearchFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Try again.'**
  String get generalSearchFailedTryAgain;

  /// No description provided for @generalLoadingFailedPullToRestart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Pull to retry.'**
  String get generalLoadingFailedPullToRestart;

  /// No description provided for @generalNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get generalNoInternetConnection;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsMinutesAgo(int count);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsHoursAgo(int count);

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsDaysAgo(int count);

  /// No description provided for @offerOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get offerOrderNow;

  /// No description provided for @offerOrderVia.
  ///
  /// In en, this message translates to:
  /// **'Order via Store'**
  String get offerOrderVia;

  /// No description provided for @offerFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get offerFollow;

  /// No description provided for @offerVisitInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get offerVisitInstagram;

  /// No description provided for @offerVisitFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get offerVisitFacebook;

  /// No description provided for @offerVisitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get offerVisitWebsite;

  /// No description provided for @offerOrderUberEats.
  ///
  /// In en, this message translates to:
  /// **'Order via Uber Eats'**
  String get offerOrderUberEats;

  /// No description provided for @offerOrderPickMe.
  ///
  /// In en, this message translates to:
  /// **'Order via PickMe'**
  String get offerOrderPickMe;

  /// No description provided for @offerEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days} days'**
  String offerEndsIn(String days);

  /// No description provided for @offerEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get offerEndsToday;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'si': return AppLocalizationsSi();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
