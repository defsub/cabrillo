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

import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/counts/repository.dart';
import 'package:cabrillo/miniflux/miniflux.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/miniflux/provider.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:cabrillo/player/player.dart';
import 'package:cabrillo/player/service.dart';
import 'package:cabrillo/seen/repository.dart';
import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/starred/repository.dart';
import 'package:cabrillo/starred/starred.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'app.dart';

extension AppContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;

  AppCubit get app => read<AppCubit>();

  ClientRepository get clientRepository => read<ClientRepository>();

  SeenRepository get seenRepository => read<SeenRepository>();

  StarredRepository get starredRepository => read<StarredRepository>();

  CountsRepository get countsRepository => read<CountsRepository>();

  PlayerService get playerService => read<PlayerService>();

  MinifluxCubit get miniflux => read<MinifluxCubit>();

  CountsCubit get counts => read<CountsCubit>();

  SeenCubit get seen => read<SeenCubit>();

  StarredCubit get starred => read<StarredCubit>();

  SettingsCubit get settings => read<SettingsCubit>();

  PlayerCubit get player => read<PlayerCubit>();

  Future<void> reload() {
    return countsRepository.reload();
  }

  void sync() {
    final state = seenRepository.cubit?.state;
    if (state != null) {
      clientRepository.updateSeen(state).then((_) {
        seenRepository.flush();
        app.syncComplete();
        reload();
      });
    }
  }

  bool enableAutoSeen(Status? status, Entry entry) {
    final autoSeen = settings.state.settings.autoSeen;
    return status == Status.unread && autoSeen && !entry.hasAudio;
  }

  void markSeen(List<Entry> list) {
    final ids = list.map((e) => e.id);
    seen.addAll(ids);
  }
}
