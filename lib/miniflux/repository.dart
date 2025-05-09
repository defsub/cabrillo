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

import 'package:cabrillo/cache/json_repository.dart';
import 'package:cabrillo/settings/repository.dart';
import 'package:cabrillo/state/entry.dart';
import 'package:http/http.dart';

import 'client.dart';
import 'model.dart';
import 'provider.dart';

class ClientRepository {
  final ClientProvider _provider;
  final SettingsRepository settingsRepository;

  static const _defaultTTL = Duration(hours: 1);
  static const _defaultPageSize = 100;
  static const defaultIconTTL = Duration(hours: 24);

  ClientRepository({
    required this.settingsRepository,
    required JsonCacheRepository jsonCacheRepository,
    String? userAgent,
    ClientProvider? provider,
  }) : _provider =
           provider ??
           MinifluxClient(
             userAgent: userAgent,
             jsonCacheRepository: jsonCacheRepository,
             settingsRepository: settingsRepository,
           );

  Client get client => _provider.client;

  Duration get defaultTTL =>
      settingsRepository.settings?.pageDuration ?? _defaultTTL;

  int get defaultLimit =>
      settingsRepository.settings?.pageSize ?? _defaultPageSize;

  Future<Me> me({Duration? ttl}) => _provider.me(ttl: ttl ?? defaultTTL);

  Future<Feeds> feeds({Duration? ttl}) =>
      _provider.feeds(ttl: ttl ?? defaultTTL);

  Future<Favicon> feedIcon(Feed feed, {Duration? ttl}) =>
      _provider.feedIcon(feed, ttl: ttl ?? defaultIconTTL);

  Future<Categories> categories({Duration? ttl}) =>
      _provider.categories(ttl: ttl ?? defaultTTL);

  Future<void> updateEntries(Iterable<int> entryIds, Status status) =>
      _provider.updateEntries(entryIds, status);

  Future<void> updateSeen(EntryState state) =>
      _provider.updateEntries(state.entries, Status.read);

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
    ttl: ttl ?? defaultTTL,
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
    ttl: ttl ?? defaultTTL,
  );

  Future<Entries> categoryEntries(
    Category category, {
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
  }) => _provider.categoryEntries(
    category,
    dir: dir,
    status: status,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultTTL,
  );

  Future<Entries> feedEntries(
    Feed feed, {
    Direction? dir = defaultDirection,
    Status? status = defaultStatus,
    Order? order = defaultOrder,
    int? limit,
    Duration? ttl,
  }) => _provider.feedEntries(
    feed,
    dir: dir,
    status: status,
    order: order,
    limit: limit ?? defaultLimit,
    ttl: ttl ?? defaultTTL,
  );

  Future<void> toggle(int id) => _provider.toggle(id);

  Future<Counts> counts({Duration? ttl}) => _provider.counts(ttl: ttl);
}
