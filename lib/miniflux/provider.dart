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

import 'package:http/http.dart';

import 'model.dart';

enum Direction { asc, desc }

enum Status { read, unread, removed }

enum Order { id, status, publishedAt, categoryTitle, categoryId }

abstract class ClientProvider {
  Client get client;

  Future<Me> me({Duration? ttl = Duration.zero});

  Future<Feeds> feeds({Duration? ttl = Duration.zero});

  Future<Favicon> feedIcon(Feed feed, {Duration? ttl = Duration.zero});

  Future<Categories> categories({Duration? ttl = Duration.zero});

  Future<void> updateEntries(Iterable<int> entryIds, Status status);

  Future<Entries> starred({
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
  });

  Future<Entries> unread({
    Direction? dir,
    Order? order,
    int? limit,
    Duration? ttl,
  });

  Future<Entries> entries({
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  });

  Future<Entries> categoryEntries(
    Category category, {
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  });

  Future<Entries> feedEntries(
    Feed feed, {
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  });

  Future<void> toggle(int id);

  Future<Counts> counts({Duration? ttl});
}
