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
import 'package:cabrillo/player/service.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable()
class PlayerState {
  final Entry? entry;
  final Map<int, int> positions; // TODO will remember everything for now

  PlayerState(this.entry, Map<int, int> positions)
    : positions = Map<int, int>.unmodifiable(positions);

  bool get isEmpty => entry == null;

  bool get isNotEmpty => entry != null;

  int? get position {
    return positions[entry?.id];
  }

  factory PlayerState.initial() => PlayerState(null, {});

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerStateToJson(this);
}

class PlayerReady extends PlayerState {
  PlayerReady(super.entry, super.positions);
}

class PlayerPlay extends PlayerState {
  final bool autoStart;

  PlayerPlay(super.entry, super.positions, {bool? autoStart})
    : autoStart = autoStart ?? false;
}

class PlayerPosition extends PlayerState {
  PlayerPosition(super.entry, super.positions);
}

class PlayerStop extends PlayerState {
  PlayerStop(super.entry, super.positions);
}

class PlayerCubit extends HydratedCubit<PlayerState> {
  final PlayerService service;

  PlayerCubit(this.service) : super(PlayerState.initial()) {
    service.init().whenComplete(
      () => emit(PlayerReady(state.entry, state.positions)),
    );
  }

  void play(Entry entry, {int? position, bool? autoStart}) {
    var m = state.positions;
    if (position != null) {
      m = Map<int, int>.from(m);
      m[entry.id] = position;
    }
    emit(PlayerPlay(entry, m, autoStart: autoStart));
  }

  void update(int position) {
    final m = Map<int, int>.from(state.positions);
    final entry = state.entry;
    if (entry != null) {
      m[entry.id] = position;
    }
    emit(PlayerPosition(state.entry, m));
  }

  void stop() => emit(PlayerStop(null, state.positions));

  @override
  PlayerState fromJson(Map<String, dynamic> json) =>
      PlayerState.fromJson(json['player'] as Map<String, dynamic>);

  @override
  Map<String, dynamic>? toJson(PlayerState state) => {'player': state.toJson()};
}
