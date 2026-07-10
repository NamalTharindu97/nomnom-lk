// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appName => 'NomNom LK';

  @override
  String get splashTagline => 'ශ්‍රී ලංකාවේ හොඳම ආහාර දීමනා සොයා ගන්න';

  @override
  String get loginTitle => 'පුරන්න';

  @override
  String get loginEmailLabel => 'ඊමේල්';

  @override
  String get loginPasswordLabel => 'මුරපදය';

  @override
  String get loginSignInButton => 'පුරන්න';

  @override
  String get loginContinueWithGoogle => 'Google සමඟ ඉදිරියට යන්න';

  @override
  String get loginNoAccount => 'ගිණුමක් නැද්ද?';

  @override
  String get loginRegisterLink => 'ලියාපදිංචි වන්න';

  @override
  String get loginErrorGeneric => 'ප්‍රවේශය අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get loginErrorInvalidCredentials => 'වලංගු නොවන ඊමේල් හෝ මුරපදය';

  @override
  String get loginSigningIn => 'පුරන්නේ...';

  @override
  String get loginOrContinueWith => 'හෝ ඉදිරියට යන්න';

  @override
  String get loginContinueWithEmail => 'ඊමේල් සමඟ ඉදිරියට යන්න';

  @override
  String get loginEmailHint => 'ඔබගේ ඊමේල් ඇතුළත් කරන්න';

  @override
  String get loginEmailInvalid => 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න';

  @override
  String get loginPasswordHint => 'ඔබගේ මුරපදය ඇතුළත් කරන්න';

  @override
  String get loginPasswordMinChars => 'අවම වශයෙන් අක්ෂර 8ක්';

  @override
  String get loginErrorSuspended => 'ඔබගේ ගිණුම අත්හිටුවා ඇත.';

  @override
  String get loginErrorGoogleEmail => 'මෙම ඊමේල් Google පිවිසුම භාවිතා කරයි.';

  @override
  String get loginEmailVerificationRequired => 'කරුණාකර පළමුව ඔබගේ ඊමේල් තහවුරු කරන්න';

  @override
  String get loginResend => 'නැවත යවන්න';

  @override
  String get homeHotOffers => 'උණුසුම් දීමනා';

  @override
  String get homeBestDeals => 'ඔබ අසල හොඳම දීමනා';

  @override
  String get homeBestDealsSubtitle => 'ඔබේ ප්‍රියතම ස්ථානවලින් හොඳම ආහාර දීමනා සොයා ගන්න.';

  @override
  String get homeNoDeals => 'තව දීමනා නැත';

  @override
  String get homeNoDealsSubtitle => 'ඔබේ ප්‍රියතම අවන්හල්වලින් නව දීමනා සඳහා නැවත පරීක්ෂා කරන්න.';

  @override
  String get homeRestaurants => 'අවන්හල්';

  @override
  String get homeSearchHint => 'කොත්තු, හොප්පර්, අවන්හල් සොයන්න...';

  @override
  String homeDealCount(int count) {
    return '$count දීමනා';
  }

  @override
  String get searchHint => 'කෑම වර්ග, අවන්හල් හෝ ආහාර වර්ග සොයන්න...';

  @override
  String get searchEmptyTitle => 'ඔබට අවශ්‍ය කුමක්ද?';

  @override
  String get searchEmptySubtitle => 'කෑම වර්ග, අවන්හල් හෝ ආහාර වර්ග සොයන්න.';

  @override
  String get searchNoResults => 'දීමනා හමු නොවීය';

  @override
  String get searchNoResultsSubtitle => 'වෙනත් කෑම වර්ගයක් හෝ අවන්හල් නමක් උත්සාහ කරන්න.';

  @override
  String get searchRestaurantsTab => 'අවන්හල්';

  @override
  String get searchOffersTab => 'දීමනා';

  @override
  String get searchRecent => 'මෑත';

  @override
  String get searchClearAll => 'සියල්ල හිස් කරන්න';

  @override
  String get searchFailed => 'සෙවීම අසාර්ථකයි';

  @override
  String get favoritesTitle => 'ඔබේ ප්‍රියතම';

  @override
  String get favoritesEmpty => 'ඕනෑම දීමනාවක හදවත තබා එය මෙහි සුරකින්න.';

  @override
  String get favoritesNoSavedDeals => 'සුරකින ලද දීමනා නැත';

  @override
  String get restaurantsTitle => 'සියලුම අවන්හල්';

  @override
  String get restaurantsEmpty => 'අවන්හල් හමු නොවීය.';

  @override
  String restaurantsTotal(int count) {
    return '$count මුළු';
  }

  @override
  String get restaurantsFailedToLoad => 'පූරණය අසාර්ථකයි';

  @override
  String get notificationsTitle => 'දැනුම්දීම්';

  @override
  String get notificationsEmpty => 'තව දැනුම්දීම් නැත.';

  @override
  String get notificationsMarkAllRead => 'සියල්ල කියවූ ලෙස සලකුණු කරන්න';

  @override
  String get notificationsAllCaughtUp => 'ඔබ සියල්ල දැක ඇත!';

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navSearch => 'සොයන්න';

  @override
  String get navFavorites => 'ප්‍රියතම';

  @override
  String get navRestaurants => 'අවන්හල්';

  @override
  String get navNotifications => 'දැනුම්දීම්';

  @override
  String get navProfile => 'පැතිකඩ';

  @override
  String offerDiscount(int percent) {
    return '$percent% ක් වට්ටම්';
  }

  @override
  String offerExpires(String date) {
    return 'කල් ඉකුත්වන්නේ $date';
  }

  @override
  String get offerViewDetails => 'තොරතුරු බලන්න';

  @override
  String get offerDetailsTitle => 'දීමනා විස්තර';

  @override
  String get offerOriginalPrice => 'පැරණි මිල';

  @override
  String get offerOfferPrice => 'දැන් මිල';

  @override
  String get offerLocation => 'ස්ථානය';

  @override
  String offerValidUntil(String date) {
    return '$date දක්වා වලංගුයි';
  }

  @override
  String get offerShare => 'බෙදාගන්න';

  @override
  String get offerDetailsError => 'දීමනා විස්තර පූරණය කළ නොහැක.';

  @override
  String get offerNotFound => 'දීමනාව හමු නොවීය';

  @override
  String get offerNotFoundSubtitle => 'මෙම දීමනාව ඉවත් කර තිබිය හැක.';

  @override
  String get offerRestaurantLabel => 'අවන්හල';

  @override
  String get offerDiscountLabel => 'වට්ටම්';

  @override
  String get offerDealPriceLabel => 'දීමනා මිල';

  @override
  String offerSaveAmount(String amount) {
    return '$amount ඉතිරි කරන්න';
  }

  @override
  String get registerCreateAccount => 'ඔබගේ ගිණුම සාදන්න';

  @override
  String get registerFullNameHint => 'ඔබගේ නම ඇතුළත් කරන්න';

  @override
  String get registerFullNameLabel => 'සම්පූර්ණ නම';

  @override
  String get registerEmailHint => 'ඔබගේ ඊමේල් ඇතුළත් කරන්න';

  @override
  String get registerEmailInvalid => 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න';

  @override
  String get registerEmailLabel => 'ඊමේල් ලිපිනය';

  @override
  String get registerPasswordMinChars => 'අවම වශයෙන් අක්ෂර 8ක්';

  @override
  String get registerPasswordLabel => 'මුරපදය';

  @override
  String get registerConfirmPasswordLabel => 'මුරපදය තහවුරු කරන්න';

  @override
  String get registerPasswordsDoNotMatch => 'මුරපද ගැලපෙන්නේ නැත';

  @override
  String get registerCreatingAccount => 'ගිණුම සාදමින්...';

  @override
  String get registerCreateAccountButton => 'ගිණුම සාදන්න';

  @override
  String get registerAlreadyHaveAccount => 'දැනටමත් ගිණුමක් තිබේද?';

  @override
  String get registerSignInLink => 'පුරන්න';

  @override
  String get registerErrorEmailExists => 'මෙම ඊමේල් සමඟ ගිණුමක් දැනටමත් පවතී.';

  @override
  String get registerErrorGeneric => 'ලියාපදිංචිය අසාර්ථකයි. නැවත උත්සාහ කරන්න.';

  @override
  String get verifyCheckYourEmail => 'ඔබගේ ඊමේල් පරීක්ෂා කරන්න';

  @override
  String get verifyWeSentCodeTo => 'අපි ඉලක්කම් 6ක කේතයක් යවා ඇත';

  @override
  String get verifyEnterCode => 'ඉලක්කම් 6ක කේතය ඇතුළත් කරන්න';

  @override
  String get verifyVerifying => 'තහවුරු කරමින්...';

  @override
  String get verifyVerifyAndLogin => 'තහවුරු කර පුරන්න';

  @override
  String verifyResendCodeIn(int seconds) {
    return 'තත්පර $secondsකින් කේතය නැවත යවන්න';
  }

  @override
  String get verifyResendCode => 'කේතය නැවත යවන්න';

  @override
  String get verifyUseDifferentEmail => 'වෙනත් ඊමේල් ලිපිනයක් භාවිතා කරන්න';

  @override
  String get verifyCodeResent => 'කේතය නැවත යවා ඇත!';

  @override
  String get verifyErrorGeneric => 'යම් දෝෂයක් සිදු විය. නැවත උත්සාහ කරන්න.';

  @override
  String get profileAdmin => 'පරිපාලක';

  @override
  String get profileRestaurantOwner => 'අවන්හල් හිමිකරු';

  @override
  String get profileFoodie => 'ආහාර ලෝලී';

  @override
  String get profileMyFavorites => 'මගේ ප්‍රියතම';

  @override
  String get profileSavedDeals => 'සුරකින ලද දීමනා';

  @override
  String get profileBrowseRestaurants => 'අවන්හල් පිරික්සන්න';

  @override
  String get profileViewAllRestaurants => 'සියලුම අවන්හල් බලන්න';

  @override
  String get profileAbout => 'පිළිබඳ';

  @override
  String get profileVersion => 'සංස්කරණය 1.0.0';

  @override
  String get profileTheme => 'තේමාව';

  @override
  String get profileDarkMode => 'අඳුරු ප්‍රකාරය';

  @override
  String get profileLightMode => 'ආලෝක ප්‍රකාරය';

  @override
  String get profileSaved => 'සුරකින ලදී';

  @override
  String get profileMemberSince => 'සාමාජික';

  @override
  String get profileNotificationPreferences => 'දැනුම්දීම් සැකසුම්';

  @override
  String get profileManageNotifications => 'දැනුම්දීම් සැකසුම් කළමනාකරණය කරන්න';

  @override
  String get profileShareApp => 'NomNom LK බෙදාගන්න';

  @override
  String get profileShareAppSubtitle => 'ඔබේ මිතුරන්ට කියන්න';

  @override
  String get profileShareAppMessage => 'NomNom LK බලන්න - ශ්‍රී ලංකාවේ හොඳම ආහාර දීමනා යෙදුම!';

  @override
  String get profileRateApp => 'යෙදුම ඇගයීමට ලක් කරන්න';

  @override
  String get profileRateAppSubtitle => 'සමාලෝචනයක් ලියන්න';

  @override
  String get editProfileTitle => 'පැතිකඩ සංස්කරණය කරන්න';

  @override
  String get editProfileSubtitle => 'පුද්ගලික තොරතුරු යාවත්කාලීන කරන්න';

  @override
  String get editProfileNameLabel => 'සම්පූර්ණ නම';

  @override
  String get editProfileNameRequired => 'නම අවශ්‍ය වේ';

  @override
  String get editProfilePhoneLabel => 'දුරකථන අංකය';

  @override
  String get editProfileEmailLabel => 'ඊමේල්';

  @override
  String get editProfileSave => 'වෙනස්කම් සුරකින්න';

  @override
  String get editProfileSaved => 'පැතිකඩ යාවත්කාලීන කරන ලදී';

  @override
  String get notifPrefsTitle => 'දැනුම්දීම් සැකසුම්';

  @override
  String get notifPrefsNewOffers => 'නව දීමනා';

  @override
  String get notifPrefsNewOffersDesc => 'ඔබේ ප්‍රියතම අවන්හල්වල නව දීමනා';

  @override
  String get notifPrefsPriceDrops => 'මිල පහත වැටීම්';

  @override
  String get notifPrefsPriceDropsDesc => 'සුරකින ලද දීමනාවල මිල පහත වැටෙන විට';

  @override
  String get notifPrefsOpenings => 'අවන්හල් විවෘත කිරීම්';

  @override
  String get notifPrefsOpeningsDesc => 'අසල නව අවන්හල් විවෘත වීම්';

  @override
  String get generalLoading => 'පූරණය වේ...';

  @override
  String get generalError => 'යම් දෝෂයක් සිදු විය';

  @override
  String get generalRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get generalNoInternet => 'අන්තර්ජාල සම්බන්ධතාවයක් නැත';

  @override
  String get generalGuest => 'ආගන්තුක';

  @override
  String get generalLogout => 'පිටවන්න';

  @override
  String get generalCancel => 'අවලංගු කරන්න';

  @override
  String get generalSave => 'සුරකින්න';

  @override
  String get generalDelete => 'මකන්න';

  @override
  String get generalConfirm => 'තහවුරු කරන්න';

  @override
  String get generalFailedToLoad => 'පූරණය අසාර්ථකයි';

  @override
  String get favoriteAdd => 'ප්‍රියතමයට එක් කරන්න';

  @override
  String get favoriteRemove => 'ප්‍රියතමයෙන් ඉවත් කරන්න';

  @override
  String get allLabel => 'සියල්ල';

  @override
  String get editProfileSaveError => 'පැතිකඩ සුරැකීමට නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get uploadFailed => 'රූපය උඩුගත කිරීමට අසමත් විය';

  @override
  String get featuredLabel => 'විශේෂාංග';

  @override
  String sponsoredBy(String name) => '$name විසින් අනුග්‍රහය දක්වන ලදී';

  @override
  String get languageLabel => 'භාෂාව';

  @override
  String get retryLabel => 'නැවත උත්සාහ කරන්න';

  @override
  String offerShareText(String restaurant, String deal, String title, String description) {
    return '$restaurant හි මෙම දීමනාව බලන්න!\n$title මත $deal\n\n$description\n\nදිනපතා ආහාර දීමනා සඳහා යෙදුම බාගන්න!';
  }

  @override
  String get generalSearchFailedTryAgain => 'සෙවීම අසාර්ථක විය. නැවත උත්සාහ කරන්න.';

  @override
  String get generalLoadingFailedPullToRestart => 'පූරණය කිරීමට අසමත් විය. නැවත උත්සාහ කිරීමට පහළට අදින්න.';

  @override
  String get generalNoInternetConnection => 'අන්තර්ජාල සම්බන්ධතාවක් නොමැත';

  @override
  String notificationsMinutesAgo(int count) => 'මිනිත්තු $countකට පෙර';

  @override
  String notificationsHoursAgo(int count) => 'පැය $countකට පෙර';

  @override
  String notificationsDaysAgo(int count) => 'දින $countකට පෙර';
}
