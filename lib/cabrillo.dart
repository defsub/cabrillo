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

import 'package:cabrillo/cache/json_repository.dart';
import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/counts/repository.dart';
import 'package:cabrillo/hive/hive_registrar.g.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:cabrillo/seen/repository.dart';
import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/settings/repository.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/starred/repository.dart';
import 'package:cabrillo/starred/starred.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nested/nested.dart';
import 'package:path_provider/path_provider.dart';

import 'miniflux/miniflux.dart';

const appVersion = '0.0.1'; // #version#
const appSource = 'https://cabrillo.app/';
const appHome = 'https://cabrillo.app/';

enum NavigationIndex { home, feeds, unread, starred }

class Cabrillo {
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
      jsonCacheRepository: jsonCacheRepository,
      settingsRepository: settingsRepository,
    );
    final starredRepository = StarredRepository(clientRepository);
    final countsRepository = CountsRepository(clientRepository);

    return [
      RepositoryProvider(create: (_) => settingsRepository),
      RepositoryProvider(create: (_) => clientRepository),
      RepositoryProvider(create: (_) => seenRepository),
      RepositoryProvider(create: (_) => starredRepository),
      RepositoryProvider(create: (_) => countsRepository),
    ];
  }

  List<SingleChildWidget> blocs() {
    return [
      BlocProvider(create: (_) => CabrilloCubit()),
      BlocProvider(
        lazy: false,
        create: (context) {
          final repo = context.read<CountsRepository>();
          final counts = CountsCubit(repo);
          repo.init(counts);
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
      BlocListener<SettingsCubit, SettingsState>(
        listener: (context, state) {
          print(state);
        },
      ),
      // BlocListener<SeenCubit, SeenState>(
      //   listener: (context, state) {
      //     print('read ${state.entries}');
      //   },
      // ),
    ];
  }
}

extension CabrilloContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;

  CabrilloCubit get app => read<CabrilloCubit>();

  ClientRepository get clientRepository => read<ClientRepository>();

  SeenRepository get seenRepository => read<SeenRepository>();

  StarredRepository get starredRepository => read<StarredRepository>();

  MinifluxCubit get miniflux => read<MinifluxCubit>();

  CountsCubit get counts => read<CountsCubit>();

  SeenCubit get seen => read<SeenCubit>();

  StarredCubit get starred => read<StarredCubit>();

  SettingsCubit get settings => read<SettingsCubit>();

  void sync() {
    final state = seenRepository.cubit?.state;
    if (state != null) {
      clientRepository.updateSeen(state).then((_) {
        seenRepository.flush();
        clientRepository.categories(ttl: Duration.zero);
        counts.reload();
      });
    }
  }
}

class CabrilloState {
  final NavigationIndex index;

  CabrilloState(this.index);

  factory CabrilloState.initial() => CabrilloState(NavigationIndex.home);

  CabrilloState copyWith({NavigationIndex? index}) =>
      CabrilloState(index ?? this.index);

  int get navigationBarIndex => index.index;
}

class CabrilloCubit extends Cubit<CabrilloState> {
  CabrilloCubit() : super(CabrilloState.initial());

  void home() => emit(state.copyWith(index: NavigationIndex.home));

  void starred() => emit(state.copyWith(index: NavigationIndex.starred));

  void goto(int index) =>
      emit(state.copyWith(index: NavigationIndex.values[index]));
}
