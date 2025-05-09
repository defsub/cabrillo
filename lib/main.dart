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

import 'package:cabrillo/player/widget.dart';
import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/settings/widget.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder, WatchContext;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:relative_time/relative_time.dart';

import 'cabrillo.dart';
import 'home.dart';
import 'log/basic_printer.dart';
import 'push.dart';

void main() async {
  // setup the logger
  Logger.level = Level.error;
  Logger.defaultFilter = () => ProductionFilter();
  Logger.defaultPrinter = () => BasicPrinter();

  WidgetsFlutterBinding.ensureInitialized();

  await Cabrillo.initStorage();

  runApp(const CabrilloApp());
}

class CabrilloApp extends StatelessWidget {
  const CabrilloApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Cabrillo().init(
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
  static final _routes = ['/home', '/feeds', '/unread', '/starred'];

  static final _navigatorKeys = {
    NavigationIndex.home: GlobalKey<NavigatorState>(),
    NavigationIndex.feeds: GlobalKey<NavigatorState>(),
    NavigationIndex.unread: GlobalKey<NavigatorState>(),
    NavigationIndex.starred: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    if (context.settings.hasApiKey) {
      // assume authenticated if there's an api key
      context.app.authenticated();
      context.app.me();
    }
  }

  NavigatorState? _navigatorState(NavigationIndex index) =>
      _navigatorKeys[index]?.currentState;

  void _onNavTapped(BuildContext context, int index) {
    if (index == NavigationIndex.sync.index) {
      Fluttertoast.showToast(
        msg: context.strings.syncCount(context.seenRepository.count),
      );
      context.sync();
      return;
    }

    final currentIndex = context.app.state.navigationBarIndex;
    if (currentIndex == index) {
      NavigatorState? navState = _navigatorState(context.app.state.index);
      if (navState != null && navState.canPop()) {
        navState.popUntil((route) => route.isFirst);
      }
    } else {
      context.app.goto(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CabrilloCubit>().state;
    if (state.authenticated == false) {
      return Scaffold(
        appBar: AppBar(title: Text(context.strings.minifluxSettings)),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: Authentication Failed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            MinifluxSettings(),
            OutlinedButton(
              child: Text(context.strings.applyLabel),
              onPressed: () {
                context.app.me();
              },
            ),
          ],
        ),
      );
    }

    final navIndex = context.app.state.index;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        NavigatorState? navState = _navigatorState(navIndex);
        if (navState != null) {
          final handled = await navState.maybePop();
          if (!handled && navIndex == NavigationIndex.home) {
            // allow pop and app to exit
            await SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // floatingActionButton: _fab(context),
        body: _body(context),
        bottomNavigationBar: _bottomNavigation(),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final state = context.app.state;
    final builders = _pageBuilders();
    final pages = List.generate(
      _routes.length,
      (index) => builders[_routes[index]]!(context),
    );
    return Column(
      children: [
        Expanded(
          child: IndexedStack(index: state.navigationBarIndex, children: pages),
        ),
        if (context.showPlayer)
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

  // Widget _fab(BuildContext context) {
  //   return BlocBuilder<SeenCubit, EntryState>(
  //     builder: (context, state) {
  //       if (state.entries.isNotEmpty) {
  //         return FloatingActionButton(
  //           child: Icon(Icons.sync),
  //           onPressed: () => context.sync(),
  //         );
  //       }
  //       return const EmptyWidget();
  //     },
  //   );
  // }

  Widget _bottomNavigation() {
    return Stack(
      children: [
        BlocBuilder<CabrilloCubit, CabrilloState>(
          builder: (context, state) {
            final index = state.navigationBarIndex;
            return BottomNavigationBar(
              showUnselectedLabels: false,
              showSelectedLabels: false,
              type: BottomNavigationBarType.fixed,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: context.strings.navHome,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.rss_feed),
                  label: context.strings.navFeeds,
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
              currentIndex: index,
              onTap: (index) => _onNavTapped(context, index),
            );
          },
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

  Map<String, WidgetBuilder> _pageBuilders() {
    final builders = {
      '/home':
          (_) =>
              CategoriesHomeWidget(key: _navigatorKeys[NavigationIndex.home]),
      '/feeds':
          (_) => FeedsHomeWidget(key: _navigatorKeys[NavigationIndex.feeds]),
      '/unread':
          (_) => UnreadHomeWidget(key: _navigatorKeys[NavigationIndex.unread]),
      '/starred':
          (_) =>
              StarredHomeWidget(key: _navigatorKeys[NavigationIndex.starred]),
    };
    return builders;
  }
}
