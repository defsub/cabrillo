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

part 'latest.g.dart';

enum LatestStatus { initial, loading, success, failure }

@JsonSerializable()
class LatestState {
  final LatestStatus status;
  final Entries entries;
  final Object? error;

  LatestState(this.status, this.entries, {this.error});

  factory LatestState.initial() =>
      LatestState(LatestStatus.initial, Entries.empty());

  factory LatestState.loading(Entries entries) =>
      LatestState(LatestStatus.loading, entries);

  factory LatestState.success(Entries entries) =>
      LatestState(LatestStatus.success, entries);

  factory LatestState.failure(Entries entries, Object error) =>
      LatestState(LatestStatus.failure, entries, error: error);

  factory LatestState.fromJson(Map<String, dynamic> json) =>
      _$LatestStateFromJson(json);

  Map<String, dynamic> toJson() => _$LatestStateToJson(this);
}

class LatestCubit extends HydratedCubit<LatestState> {
  final ClientRepository clientRepository;

  LatestCubit(this.clientRepository) : super(LatestState.initial()) {
    Future.delayed(Duration(seconds: 1), () => load());
  }

  Future<void> load({Duration? ttl}) async {
    emit(LatestState.loading(state.entries));
    try {
      final entries = await clientRepository.unread(ttl: ttl);
      emit(LatestState.success(entries));
    } catch (e) {
      emit(LatestState.failure(state.entries, e));
    }
  }

  Future<void> reload() {
    return load(ttl: Duration.zero);
  }

  @override
  LatestState fromJson(Map<String, dynamic> json) =>
      LatestState.fromJson(json['latest'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(LatestState state) => {'latest': state.toJson()};
}
