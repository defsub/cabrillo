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
import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/miniflux/provider.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/seen/widget.dart';
import 'package:cabrillo/settings/model.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/util/date.dart';
import 'package:cabrillo/util/merge.dart';
import 'package:cabrillo/widget/image.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'entries.dart';
import 'page.dart';
import 'push.dart';

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
        list.sort(
          (a, b) =>
              counts.entriesUnread(b.id).compareTo(counts.entriesUnread(a.id)),
        );
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
                          readSmallIcon()
                        else if (context.settings.state.settings.showCounts)
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
    final unreadCount = context.counts.state.entriesUnread(feed.id);
    final status = (unreadCount > 0) ? Status.unread : Status.read;
    push(context, builder: (_) => FeedEntriesWidget(feed, status));
  }
}

class FeedEntriesWidget extends ClientPage<Entries> {
  final Feed feed;
  final Status status;

  FeedEntriesWidget(this.feed, this.status, {super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.feedEntries(feed, ttl: ttl, status: status);
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }

  @override
  Widget page(BuildContext context, Entries state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feed.title),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          popupMenu(context, [
            if (status == Status.unread)
              PopupItem.markPageSeen(
                context,
                (_) => _onMarkSeen(context, state.entries),
              ),
            PopupItem.reload(context, (_) => reloadPage(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: EntryListWidget(state.entries, status: status, feed: feed),
      ),
    );
  }

  void _onMarkSeen(BuildContext context, List<Entry> list) {
    context.markSeen(list);
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget(feed: feed));
  }
}
