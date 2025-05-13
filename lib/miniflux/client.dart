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

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cabrillo/cache/json_repository.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/seen/repository.dart';
import 'package:cabrillo/settings/repository.dart';
import 'package:change_case/change_case.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'provider.dart';

class ClientException implements Exception {
  final int statusCode;
  final String? url;

  const ClientException({required this.statusCode, this.url});

  bool get authenticationFailed =>
      statusCode == HttpStatus.networkAuthenticationRequired ||
      statusCode == HttpStatus.unauthorized ||
      statusCode == HttpStatus.forbidden;

  @override
  String toString() => 'ClientException: $statusCode => $url';
}

// class _ClientError extends Error {
//   final Object? message;
//
//   /// Creates a client error with the provided [message].
//   _ClientError([this.message]);
//
//   @override
//   String toString() {
//     return message != null
//         ? 'Client error: ${Error.safeToString(message)}'
//         : 'Client error';
//   }
// }

class _ClientWithUserAgent extends http.BaseClient {
  static final log = Logger();

  final http.Client _client;
  final String _userAgent;

  _ClientWithUserAgent(this._client, this._userAgent);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    log.d('${request.method} ${request.url.toString()}');
    request.headers[HttpHeaders.userAgentHeader] = _userAgent;
    return _client.send(request);
  }
}

typedef FutureGenerator<T> = Future<T> Function();

class MinifluxClient implements ClientProvider {
  static final log = Logger();

  static const headerAuthToken = 'X-Auth-Token';

  static const defaultTimeout = Duration(seconds: 5);
  static const downloadTimeout = Duration(minutes: 5);

  final SettingsRepository settingsRepository;
  final JsonCacheRepository jsonCacheRepository;
  final SeenRepository seenRepository;
  final String _userAgent;
  late http.Client _client;

  MinifluxClient({
    required this.settingsRepository,
    required this.jsonCacheRepository,
    required this.seenRepository,
    String? userAgent,
  }) : _userAgent = userAgent ?? 'Cabrillo-App' {
    _client = _ClientWithUserAgent(http.Client(), _userAgent);
  }

  @override
  http.Client get client => _client;

  String get userAgent => _userAgent;

  String get endpoint {
    final settings = settingsRepository.settings;
    if (settings == null) {
      throw StateError('no settings');
    }
    if (settings.endpoint.isEmpty) {
      throw StateError('no endpoint');
    }
    return settings.endpoint;
  }

  Map<String, String> headers() {
    return {HttpHeaders.userAgentHeader: userAgent};
  }

  Map<String, String> _headersWithAuthToken() {
    return _headersAdd(
      name: headerAuthToken,
      value: settingsRepository.settings?.apiKey,
    );
  }

  Map<String, String> _headersAdd({
    Map<String, String>? headers,
    required String name,
    String? value,
  }) {
    headers = headers ?? <String, String>{};
    if (value != null) {
      headers[name] = value;
    }
    return headers;
  }

  Future<Map<String, dynamic>> _getJson(
    String uri, {
    bool cacheable = true,
    Duration? ttl,
  }) async {
    Map<String, dynamic>? cachedJson;

    final token = settingsRepository.settings?.apiKey;
    if (token == null) {
      throw const ClientException(
        statusCode: HttpStatus.networkAuthenticationRequired,
      );
    }

    if (cacheable) {
      final result = await jsonCacheRepository.get(
        uri,
        ttl: ttl,
        referenceTime: seenRepository.lastSyncTime,
      );
      if (result.exists) {
        log.d('cached $uri expired is ${result.expired}');
        try {
          cachedJson = result.read();
        } catch (e) {
          // can't parse cached json, will try to replace it
          log.w('parse failed', error: e);
        }
        if (cachedJson != null && result.expired == false) {
          // not expired so use the cached value
          return cachedJson;
        }
      }
    }

    try {
      final response = await _client
          .get(Uri.parse('$endpoint$uri'), headers: _headersWithAuthToken())
          .timeout(defaultTimeout);
      log.d('got ${response.statusCode} for $uri');
      if (response.statusCode != HttpStatus.ok) {
        if (response.statusCode >= HttpStatus.internalServerError &&
            cachedJson != null) {
          return cachedJson;
        }
        throw ClientException(
          statusCode: response.statusCode,
          url: response.request?.url.toString(),
        );
      }
      log.t('got response ${response.body}');
      if (cacheable) {
        await jsonCacheRepository.put(uri, response.bodyBytes);
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e, stackTrace) {
      if (e is SocketException || e is TimeoutException || e is TlsException) {
        if (cachedJson != null) {
          log.w('using cached json', error: e);
          return cachedJson;
        }
      }
      return Future<Map<String, dynamic>>.error(e, stackTrace);
    }
  }

  Future<List<dynamic>> _getJsonList(
    String uri, {
    bool cacheable = true,
    Duration? ttl,
  }) async {
    List<dynamic>? cachedJson;

    final token = settingsRepository.settings?.apiKey;
    if (token == null) {
      throw const ClientException(
        statusCode: HttpStatus.networkAuthenticationRequired,
      );
    }

    if (cacheable) {
      final result = await jsonCacheRepository.get(
        uri,
        ttl: ttl,
        referenceTime: seenRepository.lastSyncTime,
      );
      if (result.exists) {
        log.d('cached $uri expired is ${result.expired}');
        try {
          cachedJson = result.readList();
        } catch (e) {
          // can't parse cached json, will try to replace it
          log.w('parse failed', error: e);
        }
        if (cachedJson != null && result.expired == false) {
          // not expired so use the cached value
          return cachedJson;
        }
      }
    }

    try {
      final response = await _client
          .get(Uri.parse('$endpoint$uri'), headers: _headersWithAuthToken())
          .timeout(defaultTimeout);
      log.d('got ${response.statusCode} for $uri');
      if (response.statusCode != HttpStatus.ok) {
        if (response.statusCode >= HttpStatus.internalServerError &&
            cachedJson != null) {
          return cachedJson;
        }
        throw ClientException(
          statusCode: response.statusCode,
          url: response.request?.url.toString(),
        );
      }
      log.t('got response ${response.body}');
      if (cacheable) {
        await jsonCacheRepository.put(uri, response.bodyBytes);
      }
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } catch (e, stackTrace) {
      if (e is SocketException || e is TimeoutException || e is TlsException) {
        if (cachedJson != null) {
          log.w('using cached json', error: e);
          return cachedJson;
        }
      }
      return Future<List<dynamic>>.error(e, stackTrace);
    }
  }

  // Future<void> _delete(String uri) async {
  //   return _method('DELETE', uri);
  // }

  Future<void> _put(String uri) async {
    return _method('PUT', uri);
  }

  // call a method w/o any input or output data.
  Future<void> _method(String method, String uri) async {
    final token = settingsRepository.settings?.apiKey;
    if (token == null) {
      throw const ClientException(
        statusCode: HttpStatus.networkAuthenticationRequired,
      );
    }

    try {
      http.Response response;
      if (method == 'DELETE') {
        response = await _client.delete(
          Uri.parse('$endpoint$uri'),
          headers: _headersWithAuthToken(),
        );
      } else if (method == 'PUT') {
        response = await _client.put(
          Uri.parse('$endpoint$uri'),
          headers: _headersWithAuthToken(),
        );
      } else {
        throw const ClientException(statusCode: HttpStatus.badRequest);
      }
      log.d('got ${response.statusCode}');
      switch (response.statusCode) {
        case HttpStatus.accepted:
        case HttpStatus.noContent:
        case HttpStatus.ok:
          // success
          //   await jsonCacheRepository.invalidate(uri);
          break;
        default:
          // failure
          throw ClientException(
            statusCode: response.statusCode,
            url: response.request?.url.toString(),
          );
      }
    } on TlsException catch (e) {
      return Future.error(e);
    }
  }

  /// no caching
  Future<Map<String, dynamic>> _putJson(
    String uri,
    Map<String, dynamic> json,
  ) async {
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
    };

    final token = settingsRepository.settings?.apiKey;
    if (token == null) {
      throw const ClientException(
        statusCode: HttpStatus.networkAuthenticationRequired,
      );
    }
    headers.addAll(_headersWithAuthToken());

    log.t(jsonEncode(json));
    try {
      final response = await _client
          .put(
            Uri.parse('$endpoint$uri'),
            headers: headers,
            body: jsonEncode(json),
          )
          .timeout(defaultTimeout);
      log.d('response ${response.statusCode}');
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.noContent) {
        throw ClientException(
          statusCode: response.statusCode,
          url: response.request?.url.toString(),
        );
      }
      if (response.body.isEmpty) {
        return <String, dynamic>{
          'reasonPhrase': response.reasonPhrase,
          'statusCode': response.statusCode,
        };
      } else {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (e, stackTrace) {
      return Future<Map<String, dynamic>>.error(e, stackTrace);
    }
  }

  /// GET /v1/me
  @override
  Future<Me> me({Duration? ttl}) async => _getJson(
    '/v1/me',
    ttl: ttl,
  ).then((j) => Me.fromJson(j)).catchError((Object e) => Future<Me>.error(e));

  /// GET /v1/feeds
  @override
  Future<Feeds> feeds({Duration? ttl}) async =>
      _getJsonList('/v1/feeds', ttl: ttl)
          .then((j) => Feeds.fromJson(j))
          .catchError((Object e) => Future<Feeds>.error(e));

  /// GET /v1/feeds/{feedID}/icon
  @override
  Future<Favicon> feedIcon(Feed feed, {Duration? ttl}) async =>
      _getJson('/v1/feeds/${feed.id}/icon', ttl: ttl)
          .then((j) => Favicon.fromJson(j))
          .catchError((Object e) => Future<Favicon>.error(e));

  /// GET /v1/categories?counts=true
  @override
  Future<Categories> categories({Duration? ttl}) async =>
      _getJsonList('/v1/categories?counts=true', ttl: ttl)
          .then((j) => Categories.fromJson(j))
          .catchError((Object e) => Future<Categories>.error(e));

  /// GET /v1/entries?starred=true
  @override
  Future<Entries> starred({
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
  }) async =>
      _getJson('/v1/entries${_p(dir, status, order, limit, true)}', ttl: ttl)
          .then((j) => Entries.fromJson(j))
          .catchError((Object e) => Future<Entries>.error(e));

  /// GET /v1/entries?status=unread
  @override
  Future<Entries> unread({
    Direction? dir,
    Order? order,
    int? limit,
    Duration? ttl,
  }) async => _getJson(
        '/v1/entries${_p(dir, Status.unread, order, limit, null)}',
        ttl: ttl,
      )
      .then((j) => Entries.fromJson(j))
      .catchError((Object e) => Future<Entries>.error(e));

  @override
  Future<Entries> entries({
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  }) async => _getJson(
        '/v1/entries${_p(dir, status, order, limit, null, query: query)}',
        ttl: ttl,
      )
      .then((j) => Entries.fromJson(j))
      .catchError((Object e) => Future<Entries>.error(e));

  /// GET /v1/categories/id/entries
  @override
  Future<Entries> categoryEntries(
    Category category, {
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  }) async => _getJson(
        '/v1/categories/${category.id}/entries${_p(dir, status, order, limit, null, query: query)}',
        ttl: ttl,
      )
      .then((j) => Entries.fromJson(j))
      .catchError((Object e) => Future<Entries>.error(e));

  /// GET /v1/feeds/id/entries
  @override
  Future<Entries> feedEntries(
    Feed feed, {
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    Duration? ttl,
    String? query,
  }) async => _getJson(
        '/v1/feeds/${feed.id}/entries${_p(dir, status, order, limit, null, query: query)}',
        ttl: ttl,
      )
      .then((j) => Entries.fromJson(j))
      .catchError((Object e) => Future<Entries>.error(e));

  /// GET /v1/entries?status=unread&direction=desc&query=xyz
  /// GET /v1/categories/22/entries?limit=1&order=id&direction=asc
  /// GET /v1/feeds/42/entries?limit=1&order=id&direction=asc

  /// PUT /v1/entries
  @override
  Future<void> updateEntries(Iterable<int> ids, Status status) async {
    final u = Update.from(ids, status);
    await _putJson('/v1/entries', u.toJson());
  }

  /// PUT /v1/entries/1234/bookmark
  @override
  Future<void> toggle(int id) async {
    return await _put('/v1/entries/$id/bookmark');
  }

  @override
  Future<Counts> counts({Duration? ttl}) async =>
      _getJson('/v1/feeds/counters', ttl: ttl)
          .then((j) => Counts.fromJson(j))
          .catchError((Object e) => Future<Counts>.error(e));

  String _p(
    Direction? dir,
    Status? status,
    Order? order,
    int? limit,
    bool? starred, {
    String? query,
  }) {
    var s = '';
    if (dir != null) {
      s += 'direction=${dir.name}';
    }
    if (status != null) {
      if (s.isNotEmpty) s += '&';
      s += 'status=${status.name}';
    }
    if (order != null) {
      if (s.isNotEmpty) s += '&';
      s += 'order=${order.name.toSnakeCase()}';
    }
    if (limit != null) {
      if (s.isNotEmpty) s += '&';
      s += 'limit=$limit';
    }
    if (starred != null) {
      if (s.isNotEmpty) s += '&';
      s += 'starred=$starred';
    }
    if (query != null) {
      if (s.isNotEmpty) s += '&';
      s += 'search=${Uri.encodeQueryComponent(query)}';
    }
    if (s.isNotEmpty) {
      s = '?$s';
    }
    return s;
  }
}
