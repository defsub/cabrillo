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

import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/pages/entry.dart';
import 'package:cabrillo/pages/push.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/settings/model.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/settings/widget.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'unread.dart';

class UnreadWidget extends StatelessWidget {
  const UnreadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UnreadCubit>().state;
    final settings = context.watch<SettingsCubit>().state.settings;

    if (state.status == UnreadStatus.loading) {
      return Center(child: CircularProgressIndicator());
    }

    final list = _sortedEntries(settings, state.unread);
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

  Future<void> reloadPage(BuildContext context) async {
    await context.unread.reload();

    if (context.mounted) {
      await context.latest.reload();
    }
    if (context.mounted) {
      return context.reload();
    }
  }

  void _onSearch(BuildContext context) {
    // TODO currently this searches all not just unread
    push(context, builder: (_) => SearchWidget());
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

void _onMarkSeen(BuildContext context, List<Entry> list) {
  context.markSeen(list);
}
