import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('nl')
  ];

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Login to Your Account'**
  String get loginTitle;

  /// Remember me checkbox label
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Login button text when loading
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingButton;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forget Password ?'**
  String get forgotPassword;

  /// Social login section title
  ///
  /// In en, this message translates to:
  /// **'Or login with'**
  String get orLoginWith;

  /// Registration prompt text part 1
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account ? '**
  String get noAccountPrompt;

  /// Registration link text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Validation error when fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFieldsError;

  /// Success message after login
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// Generic login failure message
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Explore screen title
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// Categories section title
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Books section title
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksTitle;

  /// Search results section title
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Recommended books section title
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// Best seller section title
  ///
  /// In en, this message translates to:
  /// **'Best Seller'**
  String get bestSeller;

  /// New releases section title
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get newReleases;

  /// Trending now section title
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// See more link text
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// All categories option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategory;

  /// Error message when categories fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// Error message when books fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading books'**
  String get errorLoadingBooks;

  /// Error message when recommended books fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading recommended books'**
  String get errorLoadingRecommended;

  /// Favourites screen title
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favouritesTitle;

  /// Message shown when user needs to login
  ///
  /// In en, this message translates to:
  /// **'Please login to view your favourites.'**
  String get loginPrompt;

  /// Message shown when no favourites exist
  ///
  /// In en, this message translates to:
  /// **'No favourites found'**
  String get noFavourites;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language picker title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Message when user data can't be loaded
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// Notifications settings option
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Language change option
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Subscription status option
  ///
  /// In en, this message translates to:
  /// **'Subscription Status'**
  String get subscriptionStatus;

  /// Terms of service option
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy policy option
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// About app option
  ///
  /// In en, this message translates to:
  /// **'About Spicify'**
  String get aboutApp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// Favorites tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTab;

  /// Club tab label
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get clubTab;

  /// Title for subscriber club screen
  ///
  /// In en, this message translates to:
  /// **'Subscriber Club'**
  String get subscriberClubTitle;

  /// Message shown when login is required
  ///
  /// In en, this message translates to:
  /// **'Please login to access Subscriber Club'**
  String get loginRequiredMessage;

  /// Message shown when subscription is required
  ///
  /// In en, this message translates to:
  /// **'This content is available to members'**
  String get subscribeRequiredMessage;

  /// Message shown when no content is available
  ///
  /// In en, this message translates to:
  /// **'No content found'**
  String get noContentFound;

  /// Quote section title
  ///
  /// In en, this message translates to:
  /// **'Quote of the week'**
  String get quoteOfWeek;

  /// Placeholder when quote is missing
  ///
  /// In en, this message translates to:
  /// **'Quote missing'**
  String get quoteMissing;

  /// Bonus scenes section title
  ///
  /// In en, this message translates to:
  /// **'Bonus Spicy Scenes'**
  String get bonusScenesTitle;

  /// Placeholder when poll question is missing
  ///
  /// In en, this message translates to:
  /// **'No question'**
  String get noQuestion;

  /// Sneak peek section title
  ///
  /// In en, this message translates to:
  /// **'Sneak Peek'**
  String get sneakPeekTitle;

  /// Instruction for hidden content
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get tapToReveal;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in.'**
  String get userNotLoggedIn;

  /// No description provided for @userProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile not found.'**
  String get userProfileNotFound;

  /// No description provided for @failedToFetchUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch user data.'**
  String get failedToFetchUserData;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @dateBirth.
  ///
  /// In en, this message translates to:
  /// **'Date Birth'**
  String get dateBirth;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @loginToViewNotifications.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your notifications.'**
  String get loginToViewNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any notifications yet.'**
  String get noNotifications;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play Audio'**
  String get playAudio;

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get bookDetails;

  /// No description provided for @pleaseSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Please subscribe to access this chapter'**
  String get pleaseSubscribe;

  /// No description provided for @speed1x.
  ///
  /// In en, this message translates to:
  /// **'Speed 1x'**
  String get speed1x;

  /// No description provided for @speed2x.
  ///
  /// In en, this message translates to:
  /// **'Speed 2x'**
  String get speed2x;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get bookmark;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// Title for registration screen
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Text shown during loading state
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Validation message when fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// Success message after registration
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Check your email for verification'**
  String get registrationSuccess;

  /// Generic error message when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetLinkSent;

  /// No description provided for @resetLinkError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link. Try again.'**
  String get resetLinkError;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @socialAccounts.
  ///
  /// In en, this message translates to:
  /// **'Social Accounts'**
  String get socialAccounts;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @tiktok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get tiktok;

  /// No description provided for @enterInstagramUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Instagram URL'**
  String get enterInstagramUrl;

  /// No description provided for @enterYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter YouTube URL'**
  String get enterYoutubeUrl;

  /// No description provided for @enterTiktokUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter TikTok URL'**
  String get enterTiktokUrl;

  /// No description provided for @socialAccountsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Social accounts updated successfully'**
  String get socialAccountsUpdated;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
