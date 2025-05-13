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

import 'dart:io';

import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/cache/json_repository.dart';
import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/counts/repository.dart';
import 'package:cabrillo/hive/hive_registrar.g.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:cabrillo/player/player.dart';
import 'package:cabrillo/player/service.dart' show PlayerService;
import 'package:cabrillo/seen/repository.dart';
import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/settings/repository.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/starred/repository.dart';
import 'package:cabrillo/starred/starred.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nested/nested.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';

class AppBloc {
  static late Directory _appDir;

  static Future<void> initStorage() async {
    _appDir = await getApplicationDocumentsDirectory();
    final path = '${_appDir.path}/state';

    Hive.init(path);
    Hive.registerAdapters();

    final storageDir = HydratedStorageDirectory(path);
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: storageDir,
    );
  }

  Widget init(BuildContext context, {required Widget child}) {
    return MultiRepositoryProvider(
      providers: repositories(_appDir),
      child: MultiBlocProvider(
        providers: blocs(),
        child: MultiBlocListener(listeners: listeners(context), child: child),
      ),
    );
  }

  List<SingleChildWidget> repositories(Directory directory) {
    final jsonCacheRepository = JsonCacheRepository();
    final settingsRepository = SettingsRepository();
    final seenRepository = SeenRepository();
    final clientRepository = ClientRepository(
      seenRepository: seenRepository,
      jsonCacheRepository: jsonCacheRepository,
      settingsRepository: settingsRepository,
    );
    final starredRepository = StarredRepository(clientRepository);
    final countsRepository = CountsRepository(clientRepository);
    final playerService = PlayerService();

    return [
      RepositoryProvider(create: (_) => settingsRepository),
      RepositoryProvider(create: (_) => clientRepository),
      RepositoryProvider(create: (_) => seenRepository),
      RepositoryProvider(create: (_) => starredRepository),
      RepositoryProvider(create: (_) => countsRepository),
      RepositoryProvider(create: (_) => playerService),
    ];
  }

  List<SingleChildWidget> blocs() {
    return [
      BlocProvider(
        lazy: false,
        create: (context) => PlayerCubit(context.read<PlayerService>()),
      ),
      BlocProvider(
        lazy: false,
        create: (context) {
          final clientRepository = context.read<ClientRepository>();
          final settingsRepository = context.read<SettingsRepository>();
          return AppCubit(clientRepository, settingsRepository);
        },
      ),
      BlocProvider(
        lazy: false,
        create: (context) {
          final counts = CountsCubit();
          context.read<CountsRepository>().init(counts);
          return counts;
        },
      ),
      BlocProvider(
        lazy: false,
        create: (context) {
          final seen = SeenCubit();
          context.read<SeenRepository>().init(seen);
          return seen;
        },
      ),
      BlocProvider(
        lazy: false,
        create: (context) {
          final starred = StarredCubit();
          context.read<StarredRepository>().init(starred);
          return starred;
        },
      ),
      BlocProvider(
        lazy: false,
        create: (context) {
          final settings = SettingsCubit();
          context.read<SettingsRepository>().init(settings);
          return settings;
        },
      ),
    ];
  }

  List<SingleChildWidget> listeners(BuildContext context) {
    return [
      BlocListener<PlayerCubit, PlayerState>(
        listener: (context, state) {
          if (state is PlayerReady) {
            context.app.playerReady();
            if (state.isNotEmpty) {
              final entry = state.entry;
              final position = state.position ?? 0;
              if (entry != null) {
                context.player.play(entry, position: position);
              }
            }
          } else if (state is PlayerPlay) {
            final entry = state.entry;
            if (entry != null) {
              final playerService = context.playerService;
              playerService
                  .playEntry(entry, position: state.position)
                  .whenComplete(() {
                if (state.autoStart) {
                  playerService.play();
                }
              });
            }
          }
        },
      ),
    ];
  }
}
