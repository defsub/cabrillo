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

import 'dart:async';

import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/counts/counts.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/pages/feed.dart';
import 'package:cabrillo/pages/page.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/seen/widget.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'entry.dart';
import 'push.dart';

class CategoryTileWidget extends StatelessWidget {
  final Category category;

  const CategoryTileWidget(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<CountsCubit>().state;
    final unread = counts.categoryEntriesUnread(category.id);
    return ListTile(
      onTap: () => _onCategory(context, category),
      onLongPress: () => _onCategoryFeeds(context, category),
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
    );
  }

  void _onCategory(BuildContext context, Category category) {
    final unreadCount = context.counts.state.categoryEntriesUnread(category.id);
    final status = (unreadCount > 0) ? Status.unread : Status.read;
    push(context, builder: (_) => CategoryEntriesWidget(category, status));
  }

  void _onCategoryFeeds(BuildContext context, Category category) {
    push(context, builder: (_) => CategoryFeedsWidget(category));
  }
}

class CategoryEntriesWidget extends ClientPage<Entries> {
  final Category category;
  final Status status;

  CategoryEntriesWidget(this.category, this.status, {super.key});

  @override
  Future<void> load(BuildContext context, {Duration? ttl}) {
    return context.miniflux.categoryEntries(category, ttl: ttl, status: status);
  }

  @override
  Widget page(BuildContext context, Entries state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
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
        child: EntryListWidget(
          state.entries,
          status: status,
          category: category,
        ),
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

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget(category: category));
  }
}

class CategoryFeedsWidget extends ClientPage<Feeds> {
  final Category category;

  CategoryFeedsWidget(this.category, {super.key});

  @override
  Future<void> load(BuildContext context, {Duration? ttl}) {
    return context.miniflux.categoryFeeds(category, ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Feeds state) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.title} ${context.strings.feedsTitle}'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
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
    await super.reloadPage(context);
    if (context.mounted) {
      return context.reloadCounts();
    }
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget(category: category));
  }
}

void _onMarkSeen(BuildContext context, List<Entry> list) {
  context.markSeen(list);
}
