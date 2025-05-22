// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cabrillo => 'Cabrillo';

  @override
  String get minifluxSettings => 'Miniflux Settings';

  @override
  String get authFailed => 'Error: Authentication Failed';

  @override
  String get settingHost => 'Host';

  @override
  String get settingApiKey => 'API key';

  @override
  String get settingPageDuration => 'Page cache time';

  @override
  String get settingPageSize => 'Entries per page';

  @override
  String get settingShowCounts => 'Show unread counts';

  @override
  String get settingShowImages => 'Show images';

  @override
  String get settingShowReadingTime => 'Show reading time';

  @override
  String get settingAutoSeen => 'Mark entries as read on seen';

  @override
  String get title => 'Cabrillo';

  @override
  String get latestTitle => 'Latest';

  @override
  String get homeTitle => 'Home';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get feedsTitle => 'Feeds';

  @override
  String get unreadTitle => 'Unread';

  @override
  String get starredTitle => 'Starred';

  @override
  String get navHome => 'Home';

  @override
  String get navFeeds => 'Feeds';

  @override
  String get navStarred => 'Starred';

  @override
  String get navEntries => 'Entries';

  @override
  String get navSync => 'Sync';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get searchLabel => 'Search';

  @override
  String get aboutLabel => 'About';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get shareLabel => 'Share';

  @override
  String get openLinkLabel => 'External link';

  @override
  String get markPageReadLabel => 'Mark page as read';

  @override
  String get markSeenLabel => 'Mark read';

  @override
  String get markListenedLabel => 'Mark listened';

  @override
  String get clearLabel => 'Clear';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortUnread => 'Unread';

  @override
  String get applyLabel => 'Apply';

  @override
  String feedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
      zero: 'No feeds',
    );
    return '$_temp0';
  }

  @override
  String readingTime(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minute read',
      one: '1 minute read',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String listeningTime(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minute listen',
      one: '1 minute listen',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String syncCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: '0 entries',
    );
    return '$_temp0';
  }
}
