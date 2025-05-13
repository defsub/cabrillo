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

import 'seen.dart';

class SeenRepository {
  SeenCubit? cubit;
  DateTime? _lastSyncTime;

  void init(SeenCubit cubit) {
    this.cubit = cubit;
  }

  Iterable<int> get entries {
    return cubit?.state.entries ?? [];
  }

  void update(Iterable<int> add, Iterable<int> remove) {
    cubit?.update(add, remove);
  }

  int get count => cubit?.state.count ?? 0;

  DateTime? get lastSyncTime => _lastSyncTime;

  void flush() {
    if (cubit != null) {
      _lastSyncTime = DateTime.now();
      cubit?.flush();
    }
  }
}
