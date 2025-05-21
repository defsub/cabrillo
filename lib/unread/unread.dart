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

import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unread.g.dart';

enum UnreadStatus { initial, loading, success, failure }

@JsonSerializable()
class UnreadState {
  final UnreadStatus status;
  final Entries unread;
  final Object? error;

  UnreadState(this.status, this.unread, {this.error});

  factory UnreadState.initial() =>
      UnreadState(UnreadStatus.initial, Entries.empty());

  factory UnreadState.loading(Entries unread) =>
      UnreadState(UnreadStatus.loading, unread);

  factory UnreadState.success(Entries unread) =>
      UnreadState(UnreadStatus.success, unread);

  factory UnreadState.failure(Entries unread, Object error) =>
      UnreadState(UnreadStatus.failure, unread, error: error);

  factory UnreadState.fromJson(Map<String, dynamic> json) =>
      _$UnreadStateFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadStateToJson(this);
}

class UnreadCubit extends HydratedCubit<UnreadState> {
  final ClientRepository clientRepository;

  UnreadCubit(this.clientRepository) : super(UnreadState.initial()) {
    Future.delayed(Duration(seconds: 1), () => load());
  }

  Future<void> load({Duration? ttl}) async {
    emit(UnreadState.loading(state.unread));
    try {
      final unread = await clientRepository.unread(ttl: ttl);
      emit(UnreadState.success(unread));
    } catch (e) {
      emit(UnreadState.failure(state.unread, e));
    }
  }

  Future<void> reload() {
    return load(ttl: Duration.zero);
  }

  @override
  UnreadState fromJson(Map<String, dynamic> json) =>
      UnreadState.fromJson(json['unread'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(UnreadState state) => {'unread': state.toJson()};
}
