// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'NomNom LK';

  @override
  String get splashTagline => 'இலங்கையின் சிறந்த உணவு சலுகைகளைக் கண்டறியவும்';

  @override
  String get loginTitle => 'உள்நுழைக';

  @override
  String get loginEmailLabel => 'மின்னஞ்சல்';

  @override
  String get loginPasswordLabel => 'கடவுச்சொல்';

  @override
  String get loginSignInButton => 'உள்நுழைக';

  @override
  String get loginContinueWithGoogle => 'Google மூலம் தொடர்க';

  @override
  String get loginNoAccount => 'கணக்கு இல்லையா?';

  @override
  String get loginRegisterLink => 'பதிவு செய்க';

  @override
  String get loginErrorGeneric => 'உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorInvalidCredentials => 'தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்';

  @override
  String get loginSigningIn => 'உள்நுழைகிறது...';

  @override
  String get loginOrContinueWith => 'அல்லது தொடர்க';

  @override
  String get loginContinueWithEmail => 'மின்னஞ்சல் மூலம் தொடர்க';

  @override
  String get loginEmailHint => 'உங்கள் மின்னஞ்சலை உள்ளிடுக';

  @override
  String get loginEmailInvalid => 'சரியான மின்னஞ்சலை உள்ளிடுக';

  @override
  String get loginPasswordHint => 'உங்கள் கடவுச்சொல்லை உள்ளிடுக';

  @override
  String get loginPasswordMinChars => 'குறைந்தது 8 எழுத்துகள்';

  @override
  String get loginErrorSuspended => 'உங்கள் கணக்கு இடைநிறுத்தப்பட்டுள்ளது.';

  @override
  String get loginErrorGoogleEmail => 'இந்த மின்னஞ்சல் Google உள்நுழைவைப் பயன்படுத்துகிறது.';

  @override
  String get loginEmailVerificationRequired => 'முதலில் உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்';

  @override
  String get loginResend => 'மீண்டும் அனுப்புக';

  @override
  String get homeHotOffers => 'சூடான சலுகைகள்';

  @override
  String get homeBestDeals => 'உங்கள் அருகில் உள்ள சிறந்த சலுகைகள்';

  @override
  String get homeBestDealsSubtitle => 'உங்கள் பிடித்த இடங்களிலிருந்து சிறந்த உணவு சலுகைகளைக் கண்டறியவும்.';

  @override
  String get homeNoDeals => 'இன்னும் சலுகைகள் இல்லை';

  @override
  String get homeNoDealsSubtitle => 'உங்கள் பிடித்த உணவகங்களில் இருந்து புதிய சலுகைகளுக்காக மீண்டும் சரிபார்க்கவும்.';

  @override
  String get homeRestaurants => 'உணவகங்கள்';

  @override
  String get homeSearchHint => 'கொத்து, ஹொப்பர், உணவகங்களைத் தேடுக...';

  @override
  String homeDealCount(int count) {
    return '$count சலுகைகள்';
  }

  @override
  String get searchHint => 'உணவுகள், உணவகங்கள் அல்லது சமையல் வகைகளைத் தேடுக...';

  @override
  String get searchEmptyTitle => 'உங்களுக்கு என்ன வேண்டும்?';

  @override
  String get searchEmptySubtitle => 'உணவுகள், உணவகங்கள் அல்லது சமையல் வகைகளைத் தேடுக.';

  @override
  String get searchNoResults => 'சலுகைகள் எதுவும் கிடைக்கவில்லை';

  @override
  String get searchNoResultsSubtitle => 'வேறு உணவு அல்லது உணவகத்தின் பெயரை முயற்சிக்கவும்.';

  @override
  String get searchRestaurantsTab => 'உணவகங்கள்';

  @override
  String get searchOffersTab => 'சலுகைகள்';

  @override
  String get searchRecent => 'சமீபத்திய';

  @override
  String get searchClearAll => 'அனைத்தையும் அழிக்க';

  @override
  String get searchFailed => 'தேடல் தோல்வியடைந்தது';

  @override
  String get favoritesTitle => 'உங்கள் பிடித்தவை';

  @override
  String get favoritesEmpty => 'எந்த சலுகையிலும் இதயத்தைத் தொட்டு இங்கே சேமிக்கவும்.';

  @override
  String get favoritesNoSavedDeals => 'சேமித்த சலுகைகள் இல்லை';

  @override
  String get restaurantsTitle => 'அனைத்து உணவகங்கள்';

  @override
  String get restaurantsEmpty => 'உணவகங்கள் எதுவும் இல்லை.';

  @override
  String restaurantsTotal(int count) {
    return '$count மொத்தம்';
  }

  @override
  String get restaurantsFailedToLoad => 'ஏற்ற முடியவில்லை';

  @override
  String get notificationsTitle => 'அறிவிப்புகள்';

  @override
  String get notificationsEmpty => 'இன்னும் அறிவிப்புகள் இல்லை.';

  @override
  String get notificationsMarkAllRead => 'அனைத்தையும் வாசித்ததாகக் குறிக்கவும்';

  @override
  String get notificationsAllCaughtUp => 'நீங்கள் அனைத்தையும் பார்த்துவிட்டீர்கள்!';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navSearch => 'தேடுக';

  @override
  String get navFavorites => 'பிடித்தவை';

  @override
  String get navRestaurants => 'உணவகங்கள்';

  @override
  String get navNotifications => 'அறிவிப்புகள்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String offerDiscount(int percent) {
    return '$percent% தள்ளுபடி';
  }

  @override
  String offerExpires(String date) {
    return '$date அன்று காலாவதியாகிறது';
  }

  @override
  String get offerViewDetails => 'விவரங்களைப் பார்க்க';

  @override
  String get offerDetailsTitle => 'சலுகை விவரங்கள்';

  @override
  String get offerOriginalPrice => 'பழைய விலை';

  @override
  String get offerOfferPrice => 'இப்போதைய விலை';

  @override
  String get offerLocation => 'இருப்பிடம்';

  @override
  String offerValidUntil(String date) {
    return '$date வரை செல்லுபடியாகும்';
  }

  @override
  String get offerShare => 'பகிர்க';

  @override
  String get offerDetailsError => 'சலுகை விவரங்களை ஏற்ற முடியவில்லை.';

  @override
  String get offerNotFound => 'சலுகை கிடைக்கவில்லை';

  @override
  String get offerNotFoundSubtitle => 'இந்த சலுகை அகற்றப்பட்டிருக்கலாம்.';

  @override
  String get offerRestaurantLabel => 'உணவகம்';

  @override
  String get offerDiscountLabel => 'தள்ளுபடி';

  @override
  String get offerDealPriceLabel => 'சலுகை விலை';

  @override
  String offerSaveAmount(String amount) {
    return '$amount சேமிக்க';
  }

  @override
  String get registerCreateAccount => 'உங்கள் கணக்கை உருவாக்குக';

  @override
  String get registerFullNameHint => 'உங்கள் பெயரை உள்ளிடுக';

  @override
  String get registerFullNameLabel => 'முழுப் பெயர்';

  @override
  String get registerEmailHint => 'உங்கள் மின்னஞ்சலை உள்ளிடுக';

  @override
  String get registerEmailInvalid => 'சரியான மின்னஞ்சலை உள்ளிடுக';

  @override
  String get registerEmailLabel => 'மின்னஞ்சல் முகவரி';

  @override
  String get registerPasswordMinChars => 'குறைந்தது 8 எழுத்துகள்';

  @override
  String get registerPasswordLabel => 'கடவுச்சொல்';

  @override
  String get registerConfirmPasswordLabel => 'கடவுச்சொல்லை உறுதிப்படுத்துக';

  @override
  String get registerPasswordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get registerCreatingAccount => 'கணக்கை உருவாக்குகிறது...';

  @override
  String get registerCreateAccountButton => 'கணக்கை உருவாக்குக';

  @override
  String get registerAlreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get registerSignInLink => 'உள்நுழைக';

  @override
  String get registerErrorEmailExists => 'இந்த மின்னஞ்சலுடன் ஏற்கனவே கணக்கு உள்ளது.';

  @override
  String get registerErrorGeneric => 'பதிவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get verifyCheckYourEmail => 'உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்';

  @override
  String get verifyWeSentCodeTo => 'நாங்கள் 6 இலக்க குறியீட்டை அனுப்பியுள்ளோம்';

  @override
  String get verifyEnterCode => '6 இலக்க குறியீட்டை உள்ளிடுக';

  @override
  String get verifyVerifying => 'சரிபார்க்கிறது...';

  @override
  String get verifyVerifyAndLogin => 'சரிபார்த்து உள்நுழைக';

  @override
  String verifyResendCodeIn(int seconds) {
    return '$seconds வினாடிகளில் குறியீட்டை மீண்டும் அனுப்புக';
  }

  @override
  String get verifyResendCode => 'குறியீட்டை மீண்டும் அனுப்புக';

  @override
  String get verifyUseDifferentEmail => 'வேறு மின்னஞ்சலைப் பயன்படுத்துக';

  @override
  String get verifyCodeResent => 'குறியீடு மீண்டும் அனுப்பப்பட்டது!';

  @override
  String get verifyErrorGeneric => 'ஏதோ தவறு ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get profileAdmin => 'நிர்வாகி';

  @override
  String get profileRestaurantOwner => 'உணவக உரிமையாளர்';

  @override
  String get profileFoodie => 'உணவு ஆர்வலர்';

  @override
  String get profileMyFavorites => 'எனக்கு பிடித்தவை';

  @override
  String get profileSavedDeals => 'சேமித்த சலுகைகள்';

  @override
  String get profileBrowseRestaurants => 'உணவகங்களை உலாவுக';

  @override
  String get profileViewAllRestaurants => 'அனைத்து உணவகங்களையும் காண';

  @override
  String get profileAbout => 'பற்றி';

  @override
  String get profileVersion => 'பதிப்பு 1.0.0';

  @override
  String get profileTheme => 'தீம்';

  @override
  String get profileDarkMode => 'இருண்ட பயன்முறை';

  @override
  String get profileLightMode => 'ஒளி பயன்முறை';

  @override
  String get profileSaved => 'சேமித்தது';

  @override
  String get profileMemberSince => 'உறுப்பினர்';

  @override
  String get profileNotificationPreferences => 'அறிவிப்பு விருப்பத்தேர்வுகள்';

  @override
  String get profileManageNotifications => 'அறிவிப்பு அமைப்புகளை நிர்வகிக்க';

  @override
  String get profileShareApp => 'NomNom LK-ஐப் பகிர்க';

  @override
  String get profileShareAppSubtitle => 'உங்கள் நண்பர்களிடம் சொல்லுங்கள்';

  @override
  String get profileShareAppMessage => 'NomNom LK ஐப் பாருங்கள் - இலங்கையின் சிறந்த உணவு சலுகை பயன்பாடு!';

  @override
  String get profileRateApp => 'பயன்பாட்டை மதிப்பிடுக';

  @override
  String get profileRateAppSubtitle => 'மதிப்பாய்வு எழுதுக';

  @override
  String get editProfileTitle => 'சுயவிவரத்தைத் திருத்துக';

  @override
  String get editProfileSubtitle => 'தனிப்பட்ட தகவலைப் புதுப்பிக்க';

  @override
  String get editProfileNameLabel => 'முழுப் பெயர்';

  @override
  String get editProfileNameRequired => 'பெயர் தேவை';

  @override
  String get editProfilePhoneLabel => 'தொலைபேசி எண்';

  @override
  String get editProfileEmailLabel => 'மின்னஞ்சல்';

  @override
  String get editProfileSave => 'மாற்றங்களைச் சேமிக்க';

  @override
  String get editProfileSaved => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get notifPrefsTitle => 'அறிவிப்பு விருப்பத்தேர்வுகள்';

  @override
  String get notifPrefsNewOffers => 'புதிய சலுகைகள்';

  @override
  String get notifPrefsNewOffersDesc => 'உங்கள் பிடித்த உணவகங்களின் புதிய சலுகைகள்';

  @override
  String get notifPrefsPriceDrops => 'விலை வீழ்ச்சிகள்';

  @override
  String get notifPrefsPriceDropsDesc => 'சேமித்த சலுகைகளின் விலை குறையும் போது';

  @override
  String get notifPrefsOpenings => 'உணவக திறப்புகள்';

  @override
  String get notifPrefsOpeningsDesc => 'அருகில் புதிய உணவகங்கள் திறக்கும் போது';

  @override
  String get generalLoading => 'ஏற்றுகிறது...';

  @override
  String get generalError => 'ஏதோ தவறு ஏற்பட்டது';

  @override
  String get generalRetry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get generalNoInternet => 'இணைய இணைப்பு இல்லை';

  @override
  String get generalGuest => 'விருந்தினர்';

  @override
  String get generalLogout => 'வெளியேறுக';

  @override
  String get generalCancel => 'ரத்துசெய்';

  @override
  String get generalSave => 'சேமிக்க';

  @override
  String get generalDelete => 'நீக்குக';

  @override
  String get generalConfirm => 'உறுதிப்படுத்துக';

  @override
  String get generalFailedToLoad => 'ஏற்ற முடியவில்லை';

  @override
  String get favoriteAdd => 'பிடித்தவையில் சேர்க்க';

  @override
  String get favoriteRemove => 'பிடித்தவையிலிருந்து அகற்ற';

  @override
  String get allLabel => 'அனைத்தும்';

  @override
  String get editProfileSaveError => 'Could not save profile. Please try again.';

  @override
  String get uploadFailed => 'Failed to upload image';

  @override
  String get featuredLabel => 'Featured';

  @override
  String sponsoredBy(String name) {
    return 'Sponsored by $name';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get retryLabel => 'Retry';

  @override
  String offerShareText(String restaurant, String deal, String title, String description) {
    return 'Check out this deal at $restaurant!\n$deal on $title\n\n$description\n\nDownload the app for daily food deals in Sri Lanka!';
  }

  @override
  String get generalSearchFailedTryAgain => 'Search failed. Try again.';

  @override
  String get generalLoadingFailedPullToRestart => 'Failed to load. Pull to retry.';

  @override
  String get generalNoInternetConnection => 'No internet connection';

  @override
  String notificationsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get offerOrderNow => 'இப்போது ஆர்டர் செய்ய';

  @override
  String get offerOrderVia => 'கடை மூலம் ஆர்டர் செய்ய';

  @override
  String get offerFollow => 'பின்தொடர';

  @override
  String get offerVisitInstagram => 'Instagram';

  @override
  String get offerVisitFacebook => 'Facebook';

  @override
  String get offerVisitWebsite => 'இணையதளம்';

  @override
  String get offerOrderUberEats => 'Uber Eats மூலம் ஆர்டர் செய்யுங்கள்';

  @override
  String get offerOrderPickMe => 'PickMe மூலம் ஆர்டர் செய்யுங்கள்';

  @override
  String offerEndsIn(String days) {
    return '$days நாட்களில் முடிவடைகிறது';
  }

  @override
  String get offerEndsToday => 'இன்று முடிவடைகிறது';
}
