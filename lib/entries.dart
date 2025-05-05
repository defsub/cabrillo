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

import 'package:cabrillo/seen/seen.dart';
import 'package:cabrillo/starred/starred.dart';
import 'package:cabrillo/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'widget/button.dart';
import 'cabrillo.dart';
import 'date.dart';
import 'widget/image.dart';
import 'widget/menu.dart';
import 'miniflux/model.dart';
import 'page.dart';
import 'push.dart';

class CategoryEntriesWidget extends ClientPage<Entries> {
  final Category category;

  CategoryEntriesWidget(this.category, {super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.categoryEntries(category, ttl: ttl);
  }

  @override
  Widget page(BuildContext context, Entries state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        actions: [
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: EntryListWidget(state.entries, category: category),
      ),
    );
  }

  @override
  Future<void> reloadPage(BuildContext context) async {
    super.reloadPage(context);
    context.reload();
  }
}

class EntryListWidget extends StatelessWidget {
  final List<Entry> _entries;
  final Category? category;
  final Feed? feed;

  const EntryListWidget(this._entries, {super.key, this.feed, this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (buildContext, index) {
              final entry = _entries[index];
              final tile = EntryTileWidget(
                entry,
                category: category,
                feed: feed,
              );
              return VisibilityDetector(
                key: Key('EntryTile-${entry.id}'),
                onVisibilityChanged: (state) {
                  if (state.visibleFraction > 0.9) {
                    // print('read: ${entry.title}');
                    context.seen.add(entry.id);
                  }
                },
                child: tile,
              );
            },
          ),
        ),
      ],
    );
  }
}

class EntryTileWidget extends StatelessWidget {
  final Entry entry;
  final Category? category;
  final Feed? feed;

  const EntryTileWidget(this.entry, {super.key, this.category, this.feed});

  @override
  Widget build(BuildContext context) {
    final seen = context.watch<SeenCubit>().state.contains(entry.id);
    final starred = context.watch<StarredCubit>().state.contains(entry.id);
    final entryImage = entry.image;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onEntry(context, entry),
      child: Column(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: 32),
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (entryImage != null)
                  image(
                    width: 128,
                    height: 80,
                    padding: EdgeInsets.only(left: 8),
                    entryImage.url,
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    feedIcon(context, entry.feed, width: 20),
                    Text(
                      relativeDate(context, entry.publishedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (seen) Icon(Icons.check, size: 20),
                    SmallIconButton(
                      onPressed: () {
                        context.starredRepository.toggle(entry.id);
                      },
                      icon: Icon(
                        starred ? Icons.star : Icons.star_outline,
                        size: 20,
                      ),
                    ),
                    // SmallIconButton(
                    //   onPressed: () {},
                    //   icon: Icon(
                    //     seen
                    //         ? Icons.check_box_outlined
                    //         : Icons.check_box_outline_blank,
                    //     size: 20,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  void _onEntry(BuildContext context, Entry entry) {
    push(
      context,
      builder: (_) => EntryWidget(entry, category: category, feed: feed),
    );
  }
}

class EntryWidget extends StatelessWidget {
  final Entry entry;
  final Category? category;
  final Feed? feed;

  const EntryWidget(this.entry, {super.key, this.category, this.feed});

  @override
  Widget build(BuildContext context) {
    final starred = context.watch<StarredCubit>().state.contains(entry.id);
    final entryImage = entry.image;
    final title = category?.title ?? feed?.title ?? entry.title;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          popupMenu(context, [
            PopupItem.share(context, (_) => _onShare(context)),
            PopupItem.openLink(context, (_) => _onOpenLink(context)),
          ]),
          // popupMenu(context, [PopupItem.reload(context, (_) {})]),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(
                entry.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                trailing: IconButton(
                  onPressed: () {
                    context.starredRepository.toggle(entry.id);
                  },
                  icon: Icon(starred ? Icons.star : Icons.star_outline),
                ),
                title: Text(
                  merge([entry.feed.title, entry.author]),
                  style: Theme.of(context).textTheme.titleSmall,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  merge([
                    relativeDate(context, entry.publishedAt),
                    '${entry.readingTime} minute read',
                  ], separator: ', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (entryImage != null && entryImage.isEnclosure)
              mainImage(entryImage.url),
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: HtmlWidget(entry.content),
            ),
          ],
        ),
      ),
    );
    // Row(
    //   children: [
    //     IconButton(
    //       icon: feedIcon(context, entry.feed),
    //       onPressed: () {},
    //     ),
    //     Column(
    //       mainAxisAlignment: MainAxisAlignment.start,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           merge([entry.feed.title, entry.author]),
    //           style: Theme.of(context).textTheme.titleSmall,
    //           overflow: TextOverflow.clip,
    //         ),
    //         Text(
    //           merge([
    //             relativeDate(context, entry.publishedAt),
    //             '${entry.readingTime} minute read',
    //           ], separator: ', '),
    //           style: Theme.of(context).textTheme.bodySmall,
    //           overflow: TextOverflow.ellipsis,
    //         ),
    //       ],
  }

  void _onShare(BuildContext context) {
    final params = ShareParams(uri: Uri.parse(entry.url));
    SharePlus.instance.share(params);
  }

  void _onOpenLink(BuildContext context) {
    launchUrl(Uri.parse(entry.url));
  }
}
