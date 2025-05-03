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

import 'package:json_annotation/json_annotation.dart';

part 'entry.g.dart';

@JsonSerializable()
class EntryState {
  final Set<int> entries;

  EntryState(Iterable<int> entries) : entries = Set<int>.unmodifiable(entries);

  EntryState add(int id) {
    final s = Set<int>.from(entries);
    s.add(id);
    return EntryState(s);
  }

  EntryState addAll(Iterable<int> ids) {
    final s = Set<int>.from(entries);
    s.addAll(ids);
    return EntryState(s);
  }

  EntryState remove(int id) {
    final s = Set<int>.from(entries);
    s.remove(id);
    return EntryState(s);
  }

  EntryState removeAll(Iterable<int> ids) {
    final s = Set<int>.from(entries);
    s.removeAll(ids);
    return EntryState(s);
  }

  EntryState update(Iterable<int> add, Iterable<int> remove) {
    final s = Set<int>.from(entries);
    s.removeAll(remove);
    s.addAll(add);
    return EntryState(s);
  }

  bool contains(int id) {
    return entries.contains(id);
  }

  factory EntryState.fromJson(Map<String, dynamic> json) =>
      _$EntryStateFromJson(json);

  Map<String, dynamic> toJson() => _$EntryStateToJson(this);
}

