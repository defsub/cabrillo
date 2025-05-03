// Copyright 2025 defsub
//
// This file is part of Cabrillo.
//
// Cabrillo is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// Cabrillo is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for
// more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Cabrillo.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cabrillo/date.dart';
import 'package:cabrillo/miniflux/provider.dart';
import 'package:html/parser.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

// get categories -> [ category ]
// get category feeds -> [ feed ]
// get feed icon -> icon
// get category entries -> [ entry ]
// get feed entries -> [ entry ]
// get entries -> [ entry ]
// get entry -> entry

// mark all feed entries as read
// mark all category entries as read
// update entries [ ids, status=read ]

// toggle bookmark for entry

// refresh feed -> 204 when complete
// refresh all feeds -> 204

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final int id;
  final int userId;
  final String title;
  final bool hideGlobally;
  final int feedCount;
  final int totalUnread;

  Category({
    required this.id,
    required this.userId,
    required this.title,
    this.hideGlobally = false,
    this.feedCount = 0,
    this.totalUnread = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

class Categories {
  final List<Category> categories;

  Categories(this.categories);

  factory Categories.fromJson(List<dynamic> json) {
    List<Category> categories = [];
    for (var e in json) {
      categories.add(Category.fromJson(e));
    }
    return Categories(categories);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Favicon {
  final int id;
  final String data;
  final String mimeType;

  Favicon({required this.id, required this.data, required this.mimeType});

  Uint8List? get bytes {
    final d = encodedData;
    if (d != null) {
      return base64Decode(d);
    }
    return null;
  }

  String? get encodedData {
    final p = data.split(',');
    // "data": "image/png;base64,iVBORw0KGgoAAA....",
    if (p.length == 2 && p[0].contains(';base64')) {
      return p[1];
    }
    return null;
  }

  factory Favicon.fromJson(Map<String, dynamic> json) =>
      _$FaviconFromJson(json);

  Map<String, dynamic> toJson() => _$FaviconToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FeedIcon {
  final int iconId;
  final int feedId;

  FeedIcon({required this.iconId, required this.feedId});

  factory FeedIcon.fromJson(Map<String, dynamic> json) =>
      _$FeedIconFromJson(json);

  Map<String, dynamic> toJson() => _$FeedIconToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Feed {
  final int id;
  final int userId;
  final String title;
  final String siteUrl;
  final String feedUrl;
  final String checkedAt;
  final String etagHeader;
  final String lastModifiedHeader;
  final String parsingErrorMessage;
  final int parsingErrorCount;
  final String scraperRules;
  final String rewriteRules;
  final String userAgent;
  final String username;
  final String password;
  final bool disabled;
  final Category category;
  final FeedIcon icon;

  Feed({
    required this.id,
    required this.userId,
    required this.title,
    required this.siteUrl,
    required this.feedUrl,
    required this.checkedAt,
    required this.etagHeader,
    required this.lastModifiedHeader,
    required this.parsingErrorMessage,
    required this.parsingErrorCount,
    required this.scraperRules,
    required this.rewriteRules,
    required this.userAgent,
    required this.username,
    required this.password,
    required this.disabled,
    required this.category,
    required this.icon,
  });

  DateTime get date => parseDate(checkedAt);

  factory Feed.fromJson(Map<String, dynamic> json) => _$FeedFromJson(json);

  Map<String, dynamic> toJson() => _$FeedToJson(this);
}

class Feeds {
  final List<Feed> feeds;

  Feeds(this.feeds);

  factory Feeds.fromJson(List<dynamic> json) {
    List<Feed> feeds = [];
    for (var e in json) {
      feeds.add(Feed.fromJson(e));
    }
    return Feeds(feeds);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Enclosure {
  final int id;
  final int userId;
  final int entryId;
  final String url;
  final String mimeType;
  final int size;
  final int mediaProgression;

  Enclosure({
    required this.id,
    required this.userId,
    required this.entryId,
    required this.url,
    required this.mimeType,
    this.size = 0,
    this.mediaProgression = 0,
  });

  bool get isImage => mimeType.startsWith("image/");

  factory Enclosure.fromJson(Map<String, dynamic> json) =>
      _$EnclosureFromJson(json);

  Map<String, dynamic> toJson() => _$EnclosureToJson(this);
}

class EntryImage {
  final String url;
  final bool isEnclosure;
  final bool isContent;

  EntryImage(this.url, {this.isContent = false, this.isEnclosure = false});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Entry {
  final int id;
  final int feedId;
  final String title;
  final String url;
  final String commentsUrl;
  final String author;
  final String content;
  final String hash;
  final String publishedAt;
  final String createdAt;
  final String status;
  final bool starred;
  final int readingTime;
  final Feed feed;
  final List<Enclosure>? enclosures;
  final DateTime _date;

  Entry({
    required this.id,
    required this.feedId,
    required this.title,
    required this.url,
    required this.commentsUrl,
    required this.author,
    required this.content,
    required this.hash,
    required this.publishedAt,
    required this.createdAt,
    required this.status,
    required this.starred,
    required this.readingTime,
    required this.feed,
    this.enclosures,
  }) : _date = parseDate(publishedAt);

  bool isRead() => status == 'read';

  bool isUnread() => status == 'unread';

  DateTime get date => _date;

  String get text {
    var result = content.replaceAllMapped(RegExp(r'<[^>]+>'), (match) {
      return '';
    });
    result = result.replaceAllMapped(RegExp(r'[ \t\n\r]+'), (match) {
      return ' ';
    });
    return (parseFragment(result).text ?? '');
  }

  EntryImage? get image {
    // first try enclosure
    final list = enclosures;
    if (list != null) {
      for (var e in list) {
        if (e.isImage) {
          return EntryImage(e.url, isEnclosure: true);
        }
      }
    }

    // next image in content
    final re = RegExp(r'^\s*(<p>|)\s*(<img [^>]+>)');
    final match = re.firstMatch(content);
    if (match != null) {
      final frag = parseFragment(match[2]);
      final img = frag.firstChild;
      if (img != null) {
        // final srcSet = img.attributes['srcset'];
        final src = img.attributes['src'];
        if (src != null) {
          return EntryImage(src, isContent: true);
        }
      }
    }

    return null;
  }

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryToJson(this);
}

abstract class EntryList {
  Iterable<Entry> get iterable;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Entries extends EntryList {
  final int total;
  final List<Entry> entries;

  Entries({required this.total, required this.entries});

  @override
  Iterable<Entry> get iterable => entries;

  Iterable<int> get ids => entries.map((e) => e.id);

  Iterable<Entry> unread() => entries.where((e) => e.isUnread());

  Iterable<Entry> read() => entries.where((e) => e.isRead());

  factory Entries.fromJson(Map<String, dynamic> json) =>
      _$EntriesFromJson(json);

  Map<String, dynamic> toJson() => _$EntriesToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Me {
  final int id;
  final String username;
  final bool isAdmin;
  final String theme;
  final String language;
  final String timezone;
  final String entrySortingDirection;
  final String stylesheet;
  final String googleId;
  final String openidConnectId;
  final int entriesPerPage;
  final bool keyboardShortcuts;
  final bool showReadingTime;
  final bool entrySwipe;
  final String lastLoginAt;

  Me({
    required this.id,
    required this.username,
    required this.isAdmin,
    required this.theme,
    required this.language,
    required this.timezone,
    required this.entrySortingDirection,
    required this.stylesheet,
    required this.googleId,
    required this.openidConnectId,
    required this.entriesPerPage,
    required this.keyboardShortcuts,
    required this.showReadingTime,
    required this.entrySwipe,
    required this.lastLoginAt,
  });

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  Map<String, dynamic> toJson() => _$MeToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Update {
  final List<int> entryIds;
  final Status status;

  Update({required this.entryIds, required this.status});

  factory Update.from(Iterable<int> entries, Status status) {
    return Update(entryIds: List.from(entries), status: status);
  }

  factory Update.fromIterable(Iterable<Entry> entries, Status status) {
    final ids = entries.map((e) => e.id).toList();
    return Update(entryIds: ids, status: status);
  }

  factory Update.fromEntries(Entries entries, Status status) =>
      Update.fromIterable(entries.entries, status);

  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Counts {
  final Map<String, int> reads;
  final Map<String, int> unreads;

  Counts({required this.reads, required this.unreads});

  factory Counts.zero() => Counts(reads: {}, unreads: {});

  factory Counts.fromJson(Map<String, dynamic> json) => _$CountsFromJson(json);

  Map<String, dynamic> toJson() => _$CountsToJson(this);
}
