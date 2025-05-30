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

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

enum SortOrder { newest, oldest, title, unread }

@JsonSerializable()
class Settings {
  final String user;
  final String host;
  final String apiKey;
  final int? pageSize;
  final SortOrder feedsSort;
  final SortOrder categoriesSort;
  final SortOrder entriesSort;
  final Duration pageDuration;
  final bool showCounts;
  final bool showReadingTime;
  final bool showImages;
  final bool autoSeen;

  Settings({
    required this.user,
    required this.host,
    required this.apiKey,
    required this.pageSize,
    required this.feedsSort,
    required this.categoriesSort,
    required this.entriesSort,
    required this.pageDuration,
    required this.showCounts,
    required this.showReadingTime,
    required this.showImages,
    required this.autoSeen,
  });

  factory Settings.initial() => Settings(
    user: '',
    host: 'reader.miniflux.app',
    apiKey: '',
    pageSize: 100,
    feedsSort: SortOrder.unread,
    categoriesSort: SortOrder.title,
    entriesSort: SortOrder.newest,
    pageDuration: Duration(hours: 1),
    showCounts: true,
    showImages: true,
    showReadingTime: true,
    autoSeen: false,
  );

  bool get hasApiKey => apiKey.isNotEmpty;

  String get endpoint {
    if (host.startsWith(RegExp(r'(http|https)://.+/'))) {
      return host;
    } else if (host.contains(RegExp(r'^[a-zA-Z0-9\\.-]+$'))) {
      return 'https://$host';
    } else {
      return host;
    }
  }

  Settings copyWith({
    String? user,
    String? host,
    String? apiKey,
    SortOrder? feedsSort,
    SortOrder? categoriesSort,
    SortOrder? entriesSort,
    int? pageSize,
    Duration? pageDuration,
    bool? showCounts,
    bool? showImages,
    bool? showReadingTime,
    bool? autoSeen,
  }) => Settings(
    user: user ?? this.user,
    host: host ?? this.host,
    apiKey: apiKey ?? this.apiKey,
    pageSize: pageSize ?? this.pageSize,
    feedsSort: feedsSort ?? this.feedsSort,
    categoriesSort: categoriesSort ?? this.categoriesSort,
    entriesSort: entriesSort ?? this.entriesSort,
    pageDuration: pageDuration ?? this.pageDuration,
    showCounts: showCounts ?? this.showCounts,
    showImages: showImages ?? this.showImages,
    showReadingTime: showReadingTime ?? this.showReadingTime,
    autoSeen: autoSeen ?? this.autoSeen,
  );

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}
