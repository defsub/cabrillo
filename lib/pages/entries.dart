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
import 'package:cabrillo/miniflux/provider.dart';
import 'package:cabrillo/pages/page.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/seen/widget.dart';
import 'package:cabrillo/settings/settings.dart';
import 'package:cabrillo/starred/widget.dart';
import 'package:cabrillo/util/date.dart';
import 'package:cabrillo/util/merge.dart';
import 'package:cabrillo/widget/image.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'push.dart';

class CategoryEntriesWidget extends ClientPage<Entries> {
  final Category category;
  final Status status;

  CategoryEntriesWidget(this.category, this.status, {super.key});

  @override
  void load(BuildContext context, {Duration? ttl}) {
    context.miniflux.categoryEntries(category, ttl: ttl, status: status);
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
    super.reloadPage(context);
    context.reload();
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget(category: category));
  }
}

class EntryListWidget extends StatelessWidget {
  final List<Entry> _entries;
  final Category? category;
  final Feed? feed;
  final Status? status;

  const EntryListWidget(
    this._entries, {
    super.key,
    this.feed,
    this.status,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsCubit>();
    final screen = MediaQuery.of(context).size;
    final w = screen.width / 4;
    final h = w / 1.25;
    return Container(
      padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (buildContext, index) {
                final entry = _entries[index];
                final tile = EntryTileWidget(
                  entry,
                  status: status,
                  category: category,
                  feed: feed,
                  size: Size(w, h),
                );
                if (context.enableAutoSeen(status, entry)) {
                  return VisibilityDetector(
                    key: Key('EntryTile-${entry.id}'),
                    onVisibilityChanged: (state) {
                      if (state.visibleFraction > 0.9) {
                        context.seen.add(entry.id);
                      }
                    },
                    child: tile,
                  );
                } else {
                  return tile;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EntryTileWidget extends StatelessWidget {
  final Entry entry;
  final Status? status;
  final Category? category;
  final Feed? feed;
  final Size? size;

  const EntryTileWidget(
    this.entry, {
    super.key,
    this.status,
    this.category,
    this.feed,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // final seen = context.watch<SeenCubit>().state.contains(entry.id);
    final entryImage =
        context.settings.state.settings.showImages ? entry.image : null;
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
                    width: size?.width ?? 100,
                    height: size?.height ?? 80,
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
                    // if (entry.hasAudio) Icon(Icons.podcasts, size: 20),
                    Text(
                      merge([
                        relativeDate(context, entry.publishedAt),
                        _readingTime(context, entry),
                      ]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == Status.unread)
                      seenSmallIconButton(context, entry)
                    else
                      readSmallIcon(),
                    starredSmallIconButton(context, entry),
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
      builder:
          (_) => EntryWidget(
            entry,
            status: status,
            category: category,
            feed: feed,
          ),
    );
  }
}

class EntryWidget extends StatelessWidget {
  final Entry entry;
  final Status? status;
  final Category? category;
  final Feed? feed;

  const EntryWidget(
    this.entry, {
    super.key,
    this.status,
    this.category,
    this.feed,
  });

  @override
  Widget build(BuildContext context) {
    final entryImage =
        context.settings.state.settings.showImages ? entry.image : null;
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
                trailing: OverflowBar(
                  children: [
                    if (entry.hasAudio)
                      IconButton(
                        onPressed: () {
                          context.player.play(entry, autoStart: true);
                          context.app.showPlayer();
                        },
                        icon: Icon(Icons.play_arrow),
                      ),
                    if (status == Status.unread)
                      seenIconButton(context, entry)
                    else
                      readIcon(),
                    starredIconButton(context, entry),
                  ],
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
                    _readingTime(context, entry),
                  ], separator: ', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (entryImage != null && entryImage.isEnclosure)
              mainImage(context, entryImage.url),
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: HtmlWidget(
                entry.content,
                onTapImage: (img) {
                  showImage(context, img.sources.first.url);
                },
                onTapUrl: (url) => launchUrl(Uri.parse(url)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onShare(BuildContext context) {
    final params = ShareParams(uri: Uri.parse(entry.url));
    SharePlus.instance.share(params);
  }

  void _onOpenLink(BuildContext context) {
    launchUrl(Uri.parse(entry.url));
  }
}

String _readingTime(BuildContext context, Entry entry) {
  if (context.settings.state.settings.showReadingTime == false) {
    return '';
  }
  return (entry.hasAudio)
      ? context.strings.listeningTime(entry.readingTime)
      : context.strings.readingTime(entry.readingTime);
}
