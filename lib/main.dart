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

import 'package:cabrillo/app/app.dart';
import 'package:cabrillo/app/bloc.dart';
import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/log/basic_printer.dart';
import 'package:cabrillo/pages/auth.dart';
import 'package:cabrillo/pages/latest.dart';
import 'package:cabrillo/pages/push.dart';
import 'package:cabrillo/player/widget.dart';
import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/starred/widget.dart';
import 'package:cabrillo/unread/widget.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:relative_time/relative_time.dart';

void main() async {
  // setup the logger
  Logger.level = Level.debug;
  Logger.defaultFilter = () => ProductionFilter();
  Logger.defaultPrinter = () => BasicPrinter();

  WidgetsFlutterBinding.ensureInitialized();

  await AppBloc.initStorage();

  runApp(const CabrilloApp());
}

class CabrilloApp extends StatelessWidget {
  const CabrilloApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppBloc().init(
      context,
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          final light = ThemeData.light(useMaterial3: true);
          final dark = ThemeData.dark(useMaterial3: true);
          return MaterialApp(
            key: globalAppKey,
            onGenerateTitle: (context) => context.strings.title,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              RelativeTimeLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            // supportedLocales: const [Locale('en', '')],
            home: const _CabrilloWidget(),
            theme: light.copyWith(
              colorScheme: lightDynamic,
              listTileTheme: light.listTileTheme.copyWith(
                iconColor: light.iconTheme.color,
              ),
            ),
            darkTheme: dark.copyWith(
              colorScheme: darkDynamic,
              listTileTheme: dark.listTileTheme.copyWith(
                iconColor: dark.iconTheme.color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CabrilloWidget extends StatefulWidget {
  const _CabrilloWidget();

  @override
  State<_CabrilloWidget> createState() => __CabrilloWidgetState();
}

class __CabrilloWidgetState extends State<_CabrilloWidget> {
  NavigationIndex currentIndex = NavigationIndex.home;
  bool showPlayer = false;
  List<Widget> pages = [];
  Map<NavigationIndex, GlobalKey<NavigatorState>> _navigatorKeys = {};

  @override
  void initState() {
    super.initState();

    pages = _buildPages();

    if (context.settings.hasApiKey) {
      // assume authenticated if there's an api key
      context.app.authenticated();
      context.app.me();
    }
  }

  NavigatorState? _navigatorState(NavigationIndex index) =>
      _navigatorKeys[index]?.currentState;

  void _onNavTapped(BuildContext context, int index) {
    if (index == pages.length) {
      context.sync();
    } else if (index == currentIndex.index) {
      NavigatorState? navState = _navigatorState(currentIndex);
      if (navState != null && navState.canPop()) {
        navState.popUntil((route) => route.isFirst);
      }
    } else {
      context.app.goto(index);
    }
  }

  List<Widget> _buildPages() {
    _navigatorKeys = {
      NavigationIndex.home: GlobalKey<NavigatorState>(),
      NavigationIndex.unread: GlobalKey<NavigatorState>(),
      NavigationIndex.starred: GlobalKey<NavigatorState>(),
    };
    return [
      withNavigation(LatestPage(key: _navigatorKeys[NavigationIndex.home])),
      withNavigation(UnreadWidget(key: _navigatorKeys[NavigationIndex.unread])),
      StarredWidget(key: _navigatorKeys[NavigationIndex.starred]),
    ];
  }

  Widget withNavigation(Widget page, {String? route}) {
    return Navigator(
      key: page.key,
      initialRoute: route ?? '/',
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO add app state to rebuild/refresh pages as needed
    final state = context.watch<AppCubit>().state;
    switch (state) {
      case AppNotAuthenticated():
        return AuthWidget();
      case AppInitial():
        currentIndex = state.index;
      case AppNavChange():
        currentIndex = state.index;
      case AppShowPlayer():
        showPlayer = true;
      case AppHidePlayer():
        showPlayer = false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        NavigatorState? navState = _navigatorState(currentIndex);
        if (navState != null) {
          final handled = await navState.maybePop();
          if (!handled && currentIndex == NavigationIndex.home) {
            // allow pop and app to exit
            await SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: _body(context),
        bottomNavigationBar: _bottomNavigation(),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(index: currentIndex.index, children: pages),
        ),
        if (showPlayer)
          Dismissible(
            key: UniqueKey(),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: PlayerWidget(),
            ),
            onDismissed: (dir) {
              context.app.hidePlayer();
            },
          ),
      ],
    );
  }

  Widget _bottomNavigation() {
    return Stack(
      children: [
        BottomNavigationBar(
          showUnselectedLabels: false,
          showSelectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: context.strings.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.feed),
              label: context.strings.navEntries,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star),
              label: context.strings.navStarred,
            ),
            BottomNavigationBarItem(
              icon: _syncIcon(context),
              label: context.strings.navSync,
            ),
          ],
          currentIndex: currentIndex.index,
          onTap: (index) => _onNavTapped(context, index),
        ),
      ],
    );
  }

  Widget _syncIcon(BuildContext context) {
    final state = context.watch<SeenCubit>().state;
    final count = state.count;
    if (count == 0) {
      return Icon(Icons.sync);
    }
    return Badge(label: Text('${state.count}'), child: Icon(Icons.sync));
  }
}
