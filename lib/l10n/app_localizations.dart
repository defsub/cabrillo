import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @cabrillo.
  ///
  /// In en, this message translates to:
  /// **'Cabrillo'**
  String get cabrillo;

  /// No description provided for @minifluxSettings.
  ///
  /// In en, this message translates to:
  /// **'Miniflux Settings'**
  String get minifluxSettings;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Error: Authentication Failed'**
  String get authFailed;

  /// No description provided for @settingHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get settingHost;

  /// No description provided for @settingApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingApiKey;

  /// No description provided for @settingPageDuration.
  ///
  /// In en, this message translates to:
  /// **'Page cache time'**
  String get settingPageDuration;

  /// No description provided for @settingPageSize.
  ///
  /// In en, this message translates to:
  /// **'Entries per page'**
  String get settingPageSize;

  /// No description provided for @settingShowCounts.
  ///
  /// In en, this message translates to:
  /// **'Show unread counts'**
  String get settingShowCounts;

  /// No description provided for @settingShowImages.
  ///
  /// In en, this message translates to:
  /// **'Show images'**
  String get settingShowImages;

  /// No description provided for @settingShowReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Show reading time'**
  String get settingShowReadingTime;

  /// No description provided for @settingAutoSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark entries as read on seen'**
  String get settingAutoSeen;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Cabrillo'**
  String get title;

  /// No description provided for @latestTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @feedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feedsTitle;

  /// No description provided for @unreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unreadTitle;

  /// No description provided for @starredTitle.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starredTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFeeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get navFeeds;

  /// No description provided for @navStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get navStarred;

  /// No description provided for @navEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get navEntries;

  /// No description provided for @navSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get navSync;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @openLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get openLinkLabel;

  /// No description provided for @markPageReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark page as read'**
  String get markPageReadLabel;

  /// No description provided for @markSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markSeenLabel;

  /// No description provided for @markListenedLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark listened'**
  String get markListenedLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get sortUnread;

  /// No description provided for @applyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyLabel;

  /// No description provided for @feedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No feeds} =1{1 feed} other{{count} feeds}}'**
  String feedCount(num count);

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} =1{1 minute read} other{{count} minute read}}'**
  String readingTime(num count);

  /// No description provided for @listeningTime.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} =1{1 minute listen} other{{count} minute listen}}'**
  String listeningTime(num count);

  /// No description provided for @syncCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 entries} =1{1 entry} other{{count} entries}}'**
  String syncCount(num count);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
