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
// more details.c
//
// You should have received a copy of the GNU Affero General Public License
// along with Cabrillo.  If not, see <https://www.gnu.org/licenses/>.

import 'package:cabrillo/state/entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class SeenState {
  final EntryState seen;
  final EntryState read; // TODO this needs to be purged

  SeenState(this.seen, this.read);

  factory SeenState.initial() =>
      SeenState(EntryState.initial(), EntryState.initial());

  int get count => seen.entries.length;

  SeenState add(int id) => SeenState(seen.add(id), read);

  SeenState addAll(Iterable<int> ids) => SeenState(seen.addAll(ids), read);

  SeenState remove(int id) {
    return SeenState(seen.remove(id), read);
  }

  SeenState removeAll(Iterable<int> ids) =>
      SeenState(seen.removeAll(ids), read);

  SeenState update(Iterable<int> add, Iterable<int> remove) =>
      SeenState(seen.update(add, remove), read);

  bool contains(int id) => seen.contains(id);

  bool isRead(int id) => read.contains(id);

  SeenState sync() {
    final r = read.addAll(seen.entries);
    return SeenState(EntryState.initial(), r);
  }

  factory SeenState.fromJson(Map<String, dynamic> json) =>
      _$SeenStateFromJson(json);

  Map<String, dynamic> toJson() => _$SeenStateToJson(this);
}
