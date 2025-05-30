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

import 'package:cabrillo/cache/repository.dart';
import 'package:cabrillo/seen/model.dart';
import 'package:cabrillo/seen/repository.dart';
import 'package:cabrillo/settings/repository.dart';
import 'package:http/http.dart';

import 'client.dart';
import 'model.dart';
import 'provider.dart';

const defaultDirection = Direction.desc;
const defaultStatus = Status.unread;
const defaultOrder = Order.publishedAt;

class ClientRepository {
  final ClientProvider _provider;
  final SettingsRepository settingsRepository;
  final JsonCacheRepository jsonCacheRepository;

  static const _defaultPageTTL = Duration(hours: 1);
  static const _defaultPageSize = 100;
  static const defaultIconTTL = Duration(hours: 24);

  ClientRepository({
    required this.settingsRepository,
    required this.jsonCacheRepository,
    required SeenRepository seenRepository,
    String? userAgent,
    ClientProvider? provider,
  }) : _provider =
           provider ??
           MinifluxClient(
             userAgent: userAgent,
             seenRepository: seenRepository,
             jsonCacheRepository: jsonCacheRepository,
             settingsRepository: settingsRepository,
           );

  Client get client => _provider.client;

  Duration get defaultPageTTL =>
      settingsRepository.settings?.pageDuration ?? _defaultPageTTL;

  int get defaultLimit =>
      settingsRepository.settings?.pageSize ?? _defaultPageSize;

  Future<Me> me({Duration? ttl}) => _provider.me(ttl: ttl ?? defaultPageTTL);

  Future<Feeds> feeds({Duration? ttl}) =>
      _provider.feeds(ttl: ttl ?? defaultPageTTL);

  Future<Favicon> feedIcon(Feed feed, {Duration? ttl}) =>
      _provider.feedIcon(feed, ttl: ttl ?? defaultIconTTL);

  Future<Categories> categories({Duration? ttl}) =>
      _provider.categories(ttl: ttl ?? defaultPageTTL);

  Future<Feeds> categoryFeeds(Category category, {Duration? ttl}) =>
      _provider.categoryFeeds(category, ttl: ttl ?? defaultPageTTL);

  Future<void> updateEntries(Iterable<int> entryIds, Status status) =>
      _provider.updateEntries(entryIds, status);

  Future<void> updateSeen(SeenState state) =>
      _provider.updateEntries(state.seen.entries, Status.read);

  Future<Entries> starred({
    Direction? dir = defaultDirection,
    Status? status,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
  }) => _provider.starred(
    dir: dir,
    status: status,
    order: order,
    limit: limit,
    ttl: ttl ?? defaultPageTTL,
  );

  Future<Entries> unread({
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
  }) => _provider.unread(
    dir: dir,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultPageTTL,
  );

  Future<Entries> entries({
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
    String? query,
  }) => _provider.entries(
    dir: dir,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultPageTTL,
    query: query,
  );

  Future<Entries> categoryEntries(
    Category category, {
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
    String? query,
  }) => _provider.categoryEntries(
    category,
    dir: dir,
    status: status,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultPageTTL,
    query: query,
  );

  Future<Entries> feedEntries(
    Feed feed, {
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
    String? query,
  }) => _provider.feedEntries(
    feed,
    dir: dir,
    status: status,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultPageTTL,
    query: query,
  );

  Future<void> toggle(int id) async {
    await _provider.toggle(id);
    // invalidate anything cached with starred=
    return jsonCacheRepository.invalidate(RegExp(r'starred='));
  }

  Future<Counts> counts({Duration? ttl}) => _provider.counts(ttl: ttl);
}
