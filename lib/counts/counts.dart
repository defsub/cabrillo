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

import 'package:cabrillo/counts/repository.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';

part 'counts.g.dart';

@JsonSerializable()
class CountsState {
  final Map<String, int> reads;
  final Map<String, int> unreads;

  CountsState(this.reads, this.unreads);

  factory CountsState.zero() => CountsState({}, {});

  int read(int id) => reads['$id'] ?? 0;

  int unread(int id) => unreads['$id'] ?? 0;

  int get totalUnread => unreads.values.fold(0, (c, v) => c + v);

  factory CountsState.fromJson(Map<String, dynamic> json) =>
      _$CountsStateFromJson(json);

  Map<String, dynamic> toJson() => _$CountsStateToJson(this);
}

class CountsCubit extends HydratedCubit<CountsState> {
  final CountsRepository countsRepository;

  CountsCubit(this.countsRepository) : super(CountsState.zero());

  void update(Counts counts) => emit(CountsState(counts.reads, counts.unreads));

  void reload() {
    countsRepository.reload();
  }

  @override
  CountsState fromJson(Map<String, dynamic> json) =>
      CountsState.fromJson(json['counts'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(CountsState state) => {'counts': state.toJson()};
}
