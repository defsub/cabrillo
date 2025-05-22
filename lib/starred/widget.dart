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
import 'package:cabrillo/pages/page.dart';
import 'package:cabrillo/pages/push.dart';
import 'package:cabrillo/settings/model.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/settings/widget.dart';
import 'package:cabrillo/widget/button.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'starred.dart';

const _smallSize = 20.0;

Widget starredIconButton(BuildContext context, Entry entry) {
  final starred = context.watch<StarredCubit>().state.contains(entry.id);
  return IconButton(
    onPressed: () {
      context.starredRepository.toggle(entry.id);
    },
    icon: Icon(starred ? Icons.star : Icons.star_outline),
  );
}

Widget starredSmallIconButton(BuildContext context, Entry entry) {
  final starred = context.watch<StarredCubit>().state.contains(entry.id);
  return SmallIconButton(
    onPressed: () {
      context.starredRepository.toggle(entry.id);
    },
    icon: Icon(starred ? Icons.star : Icons.star_outline, size: _smallSize),
  );
}

class StarredWidget extends ClientPage<Entries> {
  StarredWidget({super.key});

  @override
  Future<void> load(BuildContext context, {Duration? ttl}) {
    return context.miniflux.starred(ttl: ttl);
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
    await super.reloadPage(context);
    if (context.mounted) {
      return context.reloadCounts();
    }
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
