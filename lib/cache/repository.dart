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

import 'dart:typed_data';

import 'provider.dart';

class JsonCacheResult<T> {
  final bool exists;
  final bool expired;

  JsonCacheResult(this.exists, this.expired);

  factory JsonCacheResult.notFound() => JsonCacheResult(false, false);

  T read() => throw UnimplementedError;
}

class JsonCacheRepository {
  final JsonCacheProvider _cache;

  JsonCacheRepository({JsonCacheProvider? cache})
    : _cache = cache ?? HiveJsonCache();

  Future<void> put(String uri, Uint8List body) {
    return _cache.put(uri, body);
  }

  Future<JsonCacheResult<T>> get<T>(
    String uri, {
    Duration? ttl,
    DateTime? referenceTime,
  }) {
    return _cache.get<T>(uri, ttl: ttl, referenceTime: referenceTime);
  }

  Future<void> invalidate(RegExp regexp) async {
    for (final key in _cache.keys) {
      final url = key.toString();
      if (regexp.hasMatch(url)) {
        await _cache.invalidate(url);
      }
    }
  }
}
