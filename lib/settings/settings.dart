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
import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'settings.g.dart';

@JsonSerializable()
class SettingsState {
  final Settings settings;

  SettingsState(this.settings);

  bool get hasApiKey => settings.hasApiKey;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsStateToJson(this);
}

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(SettingsState(Settings.initial()));

  bool get hasApiKey => state.hasApiKey;

  void add({
    String? user,
    String? host,
    String? apiKey,
    SortOrder? feedSort,
    int? pageSize,
  }) => emit(
    SettingsState(
      state.settings.copyWith(
        user: user,
        host: host,
        apiKey: apiKey,
        pageSize: pageSize,
        feedsSort: feedSort,
      ),
    ),
  );

  void apply(Settings settings) {
    emit(
      SettingsState(
        state.settings.copyWith(
          user: settings.user,
          host: settings.host,
          apiKey: settings.apiKey,
          pageSize: settings.pageSize,
          feedsSort: settings.feedsSort,
          categoriesSort: settings.categoriesSort,
        ),
      ),
    );
  }

  set user(String user) {
    emit(SettingsState(state.settings.copyWith(user: user)));
  }

  set host(String host) {
    emit(SettingsState(state.settings.copyWith(host: host)));
  }

  set apiKey(String apiKey) {
    emit(SettingsState(state.settings.copyWith(apiKey: apiKey)));
  }

  set pageSize(int pageSize) {
    emit(SettingsState(state.settings.copyWith(pageSize: pageSize)));
  }

  set feedSort(SortOrder order) {
    emit(SettingsState(state.settings.copyWith(feedsSort: order)));
  }

  set categoriesSort(SortOrder order) {
    emit(SettingsState(state.settings.copyWith(categoriesSort: order)));
  }

  set entriesSort(SortOrder order) {
    emit(SettingsState(state.settings.copyWith(entriesSort: order)));
  }

  @override
  SettingsState fromJson(Map<String, dynamic> json) =>
      SettingsState.fromJson(json['settings'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(SettingsState state) => {
    'settings': state.toJson(),
  };
}
