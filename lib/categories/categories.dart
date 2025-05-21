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

part 'categories.g.dart';

enum CategoriesStatus { initial, loading, success, failure }

@JsonSerializable()
class CategoriesState {
  final CategoriesStatus status;
  final Categories categories;
  final Object? error;

  CategoriesState(this.status, this.categories, {this.error});

  factory CategoriesState.initial() =>
      CategoriesState(CategoriesStatus.initial, Categories.empty());

  factory CategoriesState.loading(Categories categories) =>
      CategoriesState(CategoriesStatus.loading, categories);

  factory CategoriesState.success(Categories categories) =>
      CategoriesState(CategoriesStatus.success, categories);

  factory CategoriesState.failure(Categories categories, Object error) =>
      CategoriesState(CategoriesStatus.failure, categories, error: error);

  factory CategoriesState.fromJson(Map<String, dynamic> json) =>
      _$CategoriesStateFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriesStateToJson(this);
}

class CategoriesCubit extends HydratedCubit<CategoriesState> {
  final ClientRepository clientRepository;

  CategoriesCubit(this.clientRepository) : super(CategoriesState.initial()) {
    Future.delayed(Duration(seconds: 1), () => load());
  }

  Future<void> load({Duration? ttl}) async {
    emit(CategoriesState.loading(state.categories));
    try {
      final categories = await clientRepository.categories(ttl: ttl);
      emit(CategoriesState.success(categories));
    } catch (e) {
      emit(CategoriesState.failure(state.categories, e));
    }
  }

  Future<void> reload() {
    return load(ttl: Duration.zero);
  }

  @override
  CategoriesState fromJson(Map<String, dynamic> json) =>
      CategoriesState.fromJson(json['categories'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(CategoriesState state) => {'categories': state.toJson()};
}
