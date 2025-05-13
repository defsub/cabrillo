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

import 'json.dart';
import 'json_repository.dart';

abstract class JsonCacheProvider {
  Future<void> put(String uri, Uint8List body);

  Future<JsonCacheResult> get(
    String uri, {
    Duration? ttl,
    DateTime? referenceTime,
  });

  Future<void> invalidate(String uri);
}

class JsonCacheEntry implements JsonCacheResult {
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
  Map<String, dynamic> read() {
    return jsonDecode(data) as Map<String, dynamic>;
  }

  @override
  List<dynamic> readList() {
    return jsonDecode(data) as List<dynamic>;
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
  }

  @override
  Future<void> put(String uri, Uint8List data) async {
    await _initialized;
    final cache = CachedJson(utf8.decode(data), DateTime.now());
    // log.d('put $uri');
    return box.put(uri, cache);
  }

  @override
  Future<JsonCacheResult> get(
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
      if (referenceTime != null) {
        // older that ref time means expired
        expired = referenceTime.isAfter(lastModified);
      } else if (ttl != null) {
        final expirationTime = lastModified.add(ttl);
        expired = DateTime.now().isAfter(expirationTime);
      }
      return JsonCacheEntry(uri, cache.data, cache.lastModified, true, expired);
    }
    return JsonCacheResult.notFound();
  }

  @override
  Future<void> invalidate(String uri) {
    return box.delete(uri);
  }
}
