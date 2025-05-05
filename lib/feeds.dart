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
import 'package:cabrillo/settings/model.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cabrillo.dart';
import 'date.dart';
import 'entries.dart';
import 'miniflux/model.dart';
import 'page.dart';
import 'push.dart';
import 'widget/image.dart';
import 'widget/menu.dart';

class FeedListWidget extends StatelessWidget {
  final List<Feed> _feeds;

  const FeedListWidget(this._feeds, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = List<Feed>.from(_feeds);
    final counts = context.watch<CountsCubit>().state;
    final settings = context.watch<SettingsCubit>().state.settings;
    switch (settings.feedsSort) {
      case SortOrder.unread:
        list.sort((a, b) => counts.entriesUnread(b.id).compareTo(counts.entriesUnread(a.id)));
      case SortOrder.title:
        list.sort((a, b) => a.sortTitle.compareTo(b.sortTitle));
      case SortOrder.newest:
        list.sort((a, b) => a.date.compareTo(b.date));
      case SortOrder.oldest:
        list.sort((a, b) => b.date.compareTo(b.date));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (buildContext, index) {
              final feed = list[index];
              final unreadCount = counts.entriesUnread(feed.id);
              return Column(
                children: [
                  ListTile(
                    // enabled: counts.unread(feed.id) > 0,
                    onTap: () => _onFeed(context, feed),
                    title: Text(feed.title),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            feedIcon(context, feed),
                            Text(
                              merge([
                                relativeDate(context, feed.checkedAt),
                                feed.category.title,
                              ]),
                            ),
                          ],
                        ),
                        if (unreadCount == 0)
                          Icon(Icons.check, size: 16)
                        else
                          Text('$unreadCount'),
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

  void _onFeed(BuildContext context, Feed feed) {
    push(context, builder: (_) => FeedEntriesWidget(feed));
  }
}

class FeedEntriesWidget extends ClientPage<Entries> {
  final Feed feed;

  FeedEntriesWidget(this.feed, {super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.feedEntries(feed, ttl: ttl);
    context.reload();
  }

  @override
  Widget page(BuildContext context, Entries state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feed.title),
        actions: [
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: EntryListWidget(state.entries, feed: feed),
      ),
    );
  }
}
