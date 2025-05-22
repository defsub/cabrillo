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

import 'package:bloc/bloc.dart';
import 'package:cabrillo/miniflux/client.dart';
import 'package:cabrillo/miniflux/repository.dart';
import 'package:cabrillo/settings/repository.dart';

const appName = 'Cabrillo';
const appVersion = '0.0.5'; // #version#
const appSource = 'https://cabrillo.app/';
const appHome = 'https://cabrillo.app/';

enum NavigationIndex { home, unread, starred, sync }

class AppState {}

class AppInitial extends AppState {
  NavigationIndex index;

  AppInitial(this.index);
}

class AppAuthenticated extends AppState {}

class AppNotAuthenticated extends AppState {}

class AppShowPlayer extends AppState {}

class AppHidePlayer extends AppState {}

class AppPlayerReady extends AppState {}

class AppSyncComplete extends AppState {}

class AppNavChange extends AppState {
  NavigationIndex index;

  AppNavChange(this.index);
}

class AppCubit extends Cubit<AppState> {
  final ClientRepository clientRepository;
  final SettingsRepository settingsRepository;

  AppCubit(this.clientRepository, this.settingsRepository)
    : super(AppInitial(NavigationIndex.home));

  void authenticated() => emit(AppAuthenticated());

  void unauthenticated() => emit(AppNotAuthenticated());

  void hidePlayer() => emit(AppHidePlayer());

  void showPlayer() => emit(AppShowPlayer());

  void playerReady() => emit(AppPlayerReady());

  void syncComplete() => emit(AppSyncComplete());

  Future<void> me() {
    // TODO use fields from Me, store in state
    return clientRepository
        .me(ttl: Duration.zero)
        .then((me) => authenticated())
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

  void goto(int index) => emit(AppNavChange(NavigationIndex.values[index]));
}
