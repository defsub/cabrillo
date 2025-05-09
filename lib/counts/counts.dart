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
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';

part 'counts.g.dart';

@JsonSerializable()
class CountsState {
  final Map<String, int> reads;
  final Map<String, int> unreads;
  final Map<int, int> categoryUnreads;

  CountsState(this.reads, this.unreads, this.categoryUnreads);

  factory CountsState.zero() => CountsState({}, {}, {});

  int entriesRead(int id) => reads['$id'] ?? 0;

  int entriesUnread(int id) => unreads['$id'] ?? 0;

  int categoryEntriesUnread(int id) => categoryUnreads[id] ?? 0;

  int get totalUnread => unreads.values.fold(0, (c, v) => c + v);

  CountsState copyWith({
    Map<String, int>? reads,
    Map<String, int>? unreads,
    Map<int, int>? categoryUnreads,
  }) => CountsState(
    reads ?? this.reads,
    unreads ?? this.unreads,
    categoryUnreads ?? this.categoryUnreads,
  );

  factory CountsState.fromJson(Map<String, dynamic> json) =>
      _$CountsStateFromJson(json);

  Map<String, dynamic> toJson() => _$CountsStateToJson(this);
}

class CountsCubit extends HydratedCubit<CountsState> {
  CountsCubit() : super(CountsState.zero());

  void updateCounts(Counts counts) =>
      emit(state.copyWith(reads: counts.reads, unreads: counts.unreads));

  void updateCategories(Categories categories) {
    final counts = <int, int>{};
    for (var c in categories.categories) {
      counts[c.id] = c.totalUnread;
    }
    emit(state.copyWith(categoryUnreads: counts));
  }

  @override
  CountsState fromJson(Map<String, dynamic> json) =>
      CountsState.fromJson(json['counts'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(CountsState state) => {'counts': state.toJson()};
}
