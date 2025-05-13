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

import 'package:cabrillo/miniflux/repository.dart';

import 'counts.dart';

class CountsRepository {
  final ClientRepository clientRepository;
  CountsCubit? cubit;

  CountsRepository(this.clientRepository);

  void init(CountsCubit cubit) {
    this.cubit = cubit;
    Future.delayed(Duration(seconds: 5), () {
      reload();
    });
  }

  int read(int id) => cubit?.state.entriesRead(id) ?? 0;

  int unread(int id) => cubit?.state.entriesUnread(id) ?? 0;

  Future<void> reload() async {
    await clientRepository
        .counts(ttl: Duration.zero)
        .then((counts) {
          cubit?.updateCounts(counts);
        })
        .onError((error, stackTrace) {
          Future.delayed(const Duration(minutes: 3), () => reload());
        });
    await clientRepository
        .categories(ttl: Duration.zero)
        .then((categories) {
          cubit?.updateCategories(categories);
        })
        .onError((error, stackTrace) {
          Future.delayed(const Duration(minutes: 3), () => reload());
        });
  }
}
