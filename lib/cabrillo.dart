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
import 'package:cabrillo/miniflux/client.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:cabrillo/player/player.dart';
import 'package:cabrillo/player/service.dart';
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

const appVersion = '0.0.2'; // #version#
const appSource = 'https://cabrillo.app/';
const appHome = 'https://cabrillo.app/';

enum NavigationIndex { home, feeds, unread, starred, sync }

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
          return CabrilloCubit(clientRepository, settingsRepository);
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

extension CabrilloContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;

  CabrilloCubit get app => read<CabrilloCubit>();

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

  void reload() {
    countsRepository.reload();
  }

  void sync() {
    final state = seenRepository.cubit?.state;
    if (state != null) {
      clientRepository.updateSeen(state).then((_) {
        seenRepository.flush();
        reload();
      });
    }
  }

  bool get showPlayer => app.state.playerReady && app.state.showPlayer;

  bool enableAutoSeen(Entry entry) {
    final autoSeen = settings.state.settings.autoSeen;
    return autoSeen && !entry.hasAudio;
  }

  void markSeen(List<Entry> list) {
    final ids = list.map((e) => e.id);
    seen.addAll(ids);
  }
}

class CabrilloState {
  final NavigationIndex index;
  final bool authenticated;
  final bool showPlayer;
  final bool playerReady;

  CabrilloState(
    this.index,
    this.authenticated, {
    this.showPlayer = true,
    this.playerReady = false,
  });

  factory CabrilloState.initial() => CabrilloState(NavigationIndex.home, false);

  CabrilloState copyWith({
    NavigationIndex? index,
    bool? authenticated,
    bool? showPlayer,
    bool? playerReady,
  }) => CabrilloState(
    index ?? this.index,
    authenticated ?? this.authenticated,
    showPlayer: showPlayer ?? this.showPlayer,
    playerReady: playerReady ?? this.playerReady,
  );

  int get navigationBarIndex => index.index;
}

class CabrilloCubit extends Cubit<CabrilloState> {
  final ClientRepository clientRepository;
  final SettingsRepository settingsRepository;

  CabrilloCubit(this.clientRepository, this.settingsRepository)
    : super(CabrilloState.initial());

  void authenticated() => emit(state.copyWith(authenticated: true));

  void unauthenticated() => emit(state.copyWith(authenticated: false));

  void hidePlayer() => emit(state.copyWith(showPlayer: false));

  void showPlayer() => emit(state.copyWith(showPlayer: true));

  void playerReady() => emit(state.copyWith(playerReady: true));

  void me() {
    // TODO use fields from Me, store in state
    clientRepository
        .me(ttl: Duration.zero)
        .then((me) {
          authenticated();
        })
        .onError((e, stack) {
          if (e is ClientException && e.authenticationFailed) {
            unauthenticated();
          } else if (settingsRepository.hasApiKey) {
            // assume authenticated if there's an api key
            // but network check failed
            authenticated();
          }
        });
  }

  void goto(int index) =>
      emit(state.copyWith(index: NavigationIndex.values[index]));
}
