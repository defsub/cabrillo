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

import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'model.dart';

class SeenCubit extends HydratedCubit<SeenState> {
  SeenCubit() : super(SeenState.initial());

  void add(int entryId) => emit(state.add(entryId));

  void addAll(Iterable<int> ids) => emit(state.addAll(ids));

  void remove(int entryId) => emit(state.remove(entryId));

  void removeAll(Iterable<int> ids) => emit(state.removeAll(ids));

  void sync() => emit(state.sync());

  void update(Iterable<int> add, Iterable<int> remove) =>
      emit(state.update(add, remove));

  @override
  SeenState fromJson(Map<String, dynamic> json) =>
      SeenState.fromJson(json['seen'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(SeenState state) => {'seen': state.toJson()};
}
