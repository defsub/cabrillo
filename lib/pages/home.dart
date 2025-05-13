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
import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/miniflux/provider.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/seen/widget.dart';
import 'package:cabrillo/settings/model.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/settings/widget.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'entries.dart';
import 'feeds.dart';
import 'page.dart';
import 'push.dart';

class CategoriesHomeWidget extends NavigatorClientPage<Categories> {
  CategoriesHomeWidget({super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.categories(ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Categories state) {
    context.watch<SettingsCubit>();
    final counts = context.watch<CountsCubit>().state; // sync
    return Scaffold(
      appBar: AppBar(
        title: _title(
          context,
          context.strings.categoriesTitle,
          counts.totalUnread,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          popupMenu(context, [
            PopupItem.sortTitle(
              context,
              (context) => context.settings.categoriesSort = SortOrder.title,
            ),
            PopupItem.sortUnread(
              context,
              (context) => context.settings.categoriesSort = SortOrder.unread,
            ),
          ], icon: Icon(Icons.sort)),
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
            PopupItem.settings(context, (_) => _onSettings(context)),
            PopupItem.about(context, (_) => _onAbout(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: CategoryListWidget(state.categories),
      ),
    );
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget());
  }

  void _onAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: context.strings.cabrillo,
      applicationVersion: appVersion,
      applicationLegalese: 'Copyleft \u00a9 2025 defsub',
      // children: <Widget>[
      //   InkWell(
      //     child: const Text(
      //       appHome,
      //       style: TextStyle(
      //         decoration: TextDecoration.underline,
      //         color: Colors.blueAccent,
      //       ),
      //     ),
      //     onTap: () => launchUrl(Uri.parse(appHome)),
      //   ),
      // ],
    );
  }
}

class FeedsHomeWidget extends NavigatorClientPage<Feeds> {
  FeedsHomeWidget({super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.feeds(ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Feeds state) {
    context.watch<SettingsCubit>();
    final counts = context.watch<CountsCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: _title(context, context.strings.feedsTitle, counts.totalUnread),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          popupMenu(context, [
            PopupItem.sortTitle(
              context,
              (context) => context.settings.feedSort = SortOrder.title,
            ),
            PopupItem.sortUnread(
              context,
              (context) => context.settings.feedSort = SortOrder.unread,
            ),
          ], icon: Icon(Icons.sort)),
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
            PopupItem.settings(context, (_) => _onSettings(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: FeedListWidget(state.feeds),
      ),
    );
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget());
  }
}

class CategoryListWidget extends StatelessWidget {
  final List<Category> _categories;

  const CategoryListWidget(this._categories, {super.key});

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<CountsCubit>().state;
    final settings = context.watch<SettingsCubit>().state.settings;

    final list = List<Category>.from(_categories);
    switch (settings.categoriesSort) {
      case SortOrder.unread:
        list.sort((a, b) => b.totalUnread.compareTo(b.totalUnread));
      case SortOrder.title:
      case SortOrder.newest:
      case SortOrder.oldest:
        list.sort((a, b) => a.sortTitle.compareTo(b.sortTitle));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (buildContext, index) {
              final category = list[index];
              final unread = counts.categoryEntriesUnread(category.id);
              return Column(
                children: [
                  ListTile(
                    onTap: () => _onCategory(context, category),
                    title: Text(category.title),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.strings.feedCount(category.feedCount)),
                        if (unread == 0)
                          readSmallIcon()
                        else if (context.settings.state.settings.showCounts)
                          Text('$unread'),
                      ],
                    ),
                  ),
                  Divider(height: 6),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _onCategory(BuildContext context, Category category) {
    final unreadCount = context.counts.state.categoryEntriesUnread(category.id);
    final status = (unreadCount > 0) ? Status.unread : Status.read;
    push(context, builder: (_) => CategoryEntriesWidget(category, status));
  }
}

class UnreadHomeWidget extends NavigatorClientPage<Entries> {
  UnreadHomeWidget({super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.unread(ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Entries state) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final list = _sortedEntries(settings, state);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.unreadTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          _entriesSortMenu(context),
          popupMenu(context, [
            PopupItem.markPageSeen(context, (_) => _onMarkSeen(context, list)),
            PopupItem.reload(context, (_) => reloadPage(context)),
            PopupItem.settings(context, (_) => _onSettings(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: EntryListWidget(list, status: Status.unread),
      ),
    );
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }

  void _onSearch(BuildContext context) {
    // TODO currently this searches all not just unread
    push(context, builder: (_) => SearchWidget());
  }
}

class StarredHomeWidget extends NavigatorClientPage<Entries> {
  StarredHomeWidget({super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.starred(ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Entries state) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final list = _sortedEntries(settings, state);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.starredTitle),
        actions: [
          _entriesSortMenu(context),
          popupMenu(context, [
            PopupItem.markPageSeen(context, (_) => _onMarkSeen(context, list)),
            PopupItem.reload(context, (_) => reloadPage(context)),
            PopupItem.settings(context, (_) => _onSettings(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: EntryListWidget(list, status: Status.unread),
      ),
    );
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }
}

Widget _entriesSortMenu(BuildContext context) {
  return popupMenu(context, [
    PopupItem.sortNewest(
      context,
      (context) => context.settings.entriesSort = SortOrder.newest,
    ),
    PopupItem.sortOldest(
      context,
      (context) => context.settings.entriesSort = SortOrder.oldest,
    ),
  ], icon: Icon(Icons.sort));
}

List<Entry> _sortedEntries(Settings settings, Entries state) {
  final list = List<Entry>.from(state.entries);
  switch (settings.entriesSort) {
    case SortOrder.newest:
      list.sort((a, b) => b.date.compareTo(a.date));
    case SortOrder.oldest:
      list.sort((a, b) => a.date.compareTo(b.date));
    case SortOrder.title:
      list.sort((a, b) => b.title.compareTo(a.title));
    case SortOrder.unread:
  }
  return list;
}

void _onSettings(BuildContext context) {
  push(context, builder: (_) => const SettingsWidget());
}

Widget _title(BuildContext context, String title, int unreadCount) {
  return Text(title);
  // return (context.settings.state.settings.showCounts)
  //     ? Text('$title ($unreadCount)')
  //     : Text(title);
}

void _onMarkSeen(BuildContext context, List<Entry> list) {
  context.markSeen(list);
}
