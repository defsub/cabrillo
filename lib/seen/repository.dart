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

  void init(SeenCubit cubit) {
    this.cubit = cubit;
  }

  Iterable<int> get entries {
    return cubit?.state.entries ?? [];
  }

  void update(Iterable<int> add, Iterable<int> remove) {
    // print('update add=${List.from(add)} remove=${List.from(remove)}');
    cubit?.update(add, remove);
  }

  void flush() {
    cubit?.flush();
  }
}
