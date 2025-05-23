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

import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';

import 'model.dart';
import 'repository.dart';

const minCacheLifespan = Duration(seconds: 30);
const maxCacheLifespan = Duration(days: 14);

abstract class JsonCacheProvider {
  Future<void> put(String uri, Uint8List body);

  Future<JsonCacheResult<T>> get<T>(
    String uri, {
    Duration? ttl,
    DateTime? referenceTime,
  });

  Future<void> invalidate(String uri);
}

class JsonCacheEntry<T> implements JsonCacheResult<T> {
  final String uri;
  final String data;
  final DateTime lastModified;
  @override
  final bool exists;
  @override
  final bool expired;

  JsonCacheEntry(
    this.uri,
    this.data,
    this.lastModified,
    this.exists,
    this.expired,
  );

  @override
  T read() {
    return jsonDecode(data) as T;
  }
}

class HiveJsonCache implements JsonCacheProvider {
  late Box<CachedJson> box;
  late Future<void> _initialized;
  static final log = Logger();

  HiveJsonCache() {
    _initialized = _init();
  }

  Future<void> _init() async {
    // Note: Hive init and register adapters is called in main
    box = await Hive.openBox<CachedJson>('json_cache');
    await expire(maxCacheLifespan);
  }

  Future<void> expire(Duration ttl) async {
    final now = DateTime.now();
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        final expired = isExpired(now, ttl, value);
        if (expired) {
          log.d(
            'expiring json_cache entry (age ${now.difference(value.lastModified).inDays} days): $key',
          );
          await box.delete(key);
        }
      }
    }
  }

  @override
  Future<void> put(String uri, Uint8List data) async {
    await _initialized;
    final cache = CachedJson(utf8.decode(data), DateTime.now());
    // log.d('put $uri');
    return box.put(uri, cache);
  }

  bool isExpired(DateTime now, Duration ttl, CachedJson entry) {
    var expired = false;
    final lastModified = entry.lastModified;
    final lifespan = now.difference(lastModified);
    if (lifespan > minCacheLifespan) {
      final expirationTime = lastModified.add(ttl);
      expired = now.isAfter(expirationTime);
    }
    return expired;
  }

  @override
  Future<JsonCacheResult<T>> get<T>(
    String uri, {
    Duration? ttl,
    DateTime? referenceTime,
  }) async {
    await _initialized;
    final cache = box.get(uri);
    // log.d('get $uri -> ${cache?.data.length ?? 0} ${cache?.lastModified} $ttl');
    if (cache != null) {
      final lastModified = cache.lastModified;
      var expired = false;
      if (ttl != null) {
        expired = isExpired(DateTime.now(), ttl, cache);
      }
      if (!expired) {
        // older that ref time means expired
        expired = referenceTime?.isAfter(lastModified) ?? false;
      }
      return JsonCacheEntry<T>(
        uri,
        cache.data,
        cache.lastModified,
        true,
        expired,
      );
    }
    return JsonCacheResult.notFound();
  }

  @override
  Future<void> invalidate(String uri) {
    return box.delete(uri);
  }
}
