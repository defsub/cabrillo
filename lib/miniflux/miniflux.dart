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

import 'package:bloc/bloc.dart';
import 'package:cabrillo/seen/repository.dart';

import 'client.dart';
import 'model.dart';
import 'provider.dart';
import 'repository.dart';

class MinifluxState {}

class MinifluxReady extends MinifluxState {}

class MinifluxLoading extends MinifluxState {}

class MinifluxError extends MinifluxState {
  final Object? error;
  final StackTrace? stackTrace;

  MinifluxError(this.error, this.stackTrace);
}

class MinifluxAuthError extends MinifluxError {
  final int statusCode;

  MinifluxAuthError(this.statusCode, super.error, super.stackTrace);
}

class MinifluxResult<T> extends MinifluxState {
  final T result;

  MinifluxResult(this.result);
}

typedef MinifluxRequest<T> = Future<T> Function({Duration? ttl});

class MinifluxCubit extends Cubit<MinifluxState> {
  final ClientRepository clientRepository;
  final SeenRepository seenRepository;
  final Duration _timeout;

  MinifluxCubit(this.clientRepository, this.seenRepository, {Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 10),
      super(MinifluxReady());

  void result<T>(T v) {
    emit(MinifluxResult<T>(v));
  }

  void me({Duration? ttl}) =>
      _doit<Me>(({Duration? ttl}) => clientRepository.me(ttl: ttl), ttl: ttl);

  void feeds({Duration? ttl}) => _doit<Feeds>(
    ({Duration? ttl}) => clientRepository.feeds(ttl: ttl),
    ttl: ttl,
  );

  void categories({Duration? ttl}) => _doit<Categories>(
    ({Duration? ttl}) => clientRepository.categories(ttl: ttl),
    ttl: ttl,
  );

  void starred({Duration? ttl, Status? status}) => _doit<Entries>(
    ({Duration? ttl}) => clientRepository.starred(ttl: ttl, status: status),
    ttl: ttl,
  );

  void unread({Duration? ttl}) => _doit<Entries>(
    ({Duration? ttl}) => clientRepository.unread(ttl: ttl),
    ttl: ttl,
  );

  void categoryEntries(Category category, {Duration? ttl}) => _doit<Entries>(
    ({Duration? ttl}) => clientRepository.categoryEntries(category, ttl: ttl),
    ttl: ttl,
  );

  void feedEntries(Feed feed, {Duration? ttl}) => _doit<Entries>(
    ({Duration? ttl}) => clientRepository.feedEntries(feed, ttl: ttl),
    ttl: ttl,
  );

  void counts({Duration? ttl}) => _doit<Counts>(
    ({Duration? ttl}) => clientRepository.counts(ttl: ttl),
    ttl: ttl,
  );

  Future<void> _doit<T>(MinifluxRequest<T> call, {Duration? ttl}) async {
    emit(MinifluxLoading());
    return call(ttl: ttl)
        .timeout(_timeout)
        .then((T result) {
          if (result is EntryList) {
            final read = <int>{};
            final unread = <int>{};
            for (final e in result.iterable) {
              if (e.isRead()) {
                read.add(e.id);
              } else if (e.isUnread()) {
                unread.add(e.id); // TODO this is out of sync with local
              }
            }
            seenRepository.update(read, unread);
          }
          return emit(MinifluxResult<T>(result));
        })
        .onError(_handleError);
  }

  // call1 must be idempotent since it may be called again if call2 fails.
  // Future<void> _doit2<T>(
  //   MinifluxRequest<dynamic> call1,
  //   MinifluxRequest<T> call2, {
  //   Duration? ttl,
  // }) async {
  //   emit(MinifluxLoading());
  //   return call1(ttl: ttl)
  //       .timeout(_timeout)
  //       .then(
  //         (_) => call2(ttl: ttl)
  //             .timeout(_timeout)
  //             .then((T result) => emit(MinifluxResult<T>(result)))
  //             .onError(_handleError),
  //       )
  //       .onError(_handleError);
  // }

  // timeouts will be raised here as a TimeoutException and emitted as MinifluxError
  void _handleError(Object? error, StackTrace stackTrace) {
    if (error is ClientException && error.authenticationFailed) {
      emit(MinifluxAuthError(error.statusCode, error, stackTrace));
    } else {
      emit(MinifluxError(error, stackTrace));
    }
  }
}
