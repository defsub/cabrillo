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
import 'package:cabrillo/categories/categories.dart';
import 'package:cabrillo/latest/latest.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/pages/category.dart';
import 'package:cabrillo/pages/entry.dart';
import 'package:cabrillo/pages/push.dart';
import 'package:cabrillo/pages/search.dart';
import 'package:cabrillo/settings/widget.dart';
import 'package:cabrillo/util/date.dart';
import 'package:cabrillo/widget/empty.dart';
import 'package:cabrillo/widget/image.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class LatestPage extends StatelessWidget {
  const LatestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoriesCubit>().state;
    final latest = context.watch<LatestCubit>().state;
    if (state.status == CategoriesStatus.loading) {
      return Center(child: CircularProgressIndicator());
    }
    // final settings = context.watch<SettingsCubit>().state.settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.homeTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearch(context),
          ),
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
            PopupItem.settings(context, (_) => _onSettings(context)),
            PopupItem.about(context, (_) => _onAbout(context)),
          ]),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reloadPage(context),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: _body(context, state, latest),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CategoriesState state,
    LatestState latest,
  ) {
    final showGrid = latest.entries.withImages().length > 1;
    if (showGrid == false) {
      return CategoryList(state.categories);
    }

    final bodyHeight =
        MediaQuery.of(context).size.height - // total height
        kToolbarHeight - // top AppBar height
        MediaQuery.of(context).padding.top - // top padding
        kBottomNavigationBarHeight; // BottomNavigationBar height

    final size = MediaQuery.of(context).size;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: size.width / 2, child: CategoryList(state.categories)),
        Container(
          padding: EdgeInsets.only(right: 12),
          width: size.width / 2,
          height: bodyHeight,
          child: ImageGrid(),
        ),
      ],
    );
  }

  Future<void> reloadPage(BuildContext context) async {
    await context.categories.reload();
    if (context.mounted) {
      await context.latest.reload();
    }
    if (context.mounted) {
      return context.reload();
    }
  }

  void _onSearch(BuildContext context) {
    push(context, builder: (_) => SearchWidget());
  }

  void _onSettings(BuildContext context) {
    push(context, builder: (_) => const SettingsWidget());
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

class CategoryList extends StatelessWidget {
  final Categories categories;

  const CategoryList(this.categories, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = categories.categories;
    return Column(children: list.map((c) => CategoryTileWidget(c)).toList());
  }
}

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LatestCubit>().state;
    if (state.status == LatestStatus.loading) {
      return Center(child: CircularProgressIndicator());
    }
    final list = state.entries.withImages().toList();
    final length = list.length;
    Widget? body;
    switch (length) {
      case >= 8:
        body = grid8(list);
      case >= 7:
        body = grid7(list);
      case >= 6:
        body = grid6(list);
      case >= 5:
        body = grid5(list);
      case >= 4:
        body = grid4(list);
      case >= 3:
        body = grid3(list);
      case >= 2:
        body = grid2(list);
    }
    return Scaffold(body: body ?? EmptyWidget());
  }

  Widget grid2(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid3(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid4(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t21(list.removeAt(0)));
    tiles.add(t21(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid5(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t12(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid6(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t21(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t12(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid7(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t12(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t21(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget grid8(List<Entry> list) {
    final tiles = <StaggeredGridTile>[];
    tiles.add(t22(list.removeAt(0)));
    tiles.add(t12(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t21(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    tiles.add(t12(list.removeAt(0)));
    tiles.add(t11(list.removeAt(0)));
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }
}

StaggeredGridTile t11(Entry entry) => StaggeredGridTile.count(
  crossAxisCellCount: 1,
  mainAxisCellCount: 1,
  child: ImageTile(entry),
);

StaggeredGridTile t12(Entry entry) => StaggeredGridTile.count(
  crossAxisCellCount: 1,
  mainAxisCellCount: 2,
  child: ImageTile(entry),
);

StaggeredGridTile t21(Entry entry) => StaggeredGridTile.count(
  crossAxisCellCount: 2,
  mainAxisCellCount: 1,
  child: ImageTile(entry),
);

StaggeredGridTile t22(Entry entry) => StaggeredGridTile.count(
  crossAxisCellCount: 2,
  mainAxisCellCount: 2,
  child: ImageTile(entry),
);

class ImageTile extends StatelessWidget {
  final Entry entry;

  const ImageTile(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        push(context, builder: (_) => EntryWidget(entry, feed: entry.feed));
      },
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          image(entry.image!.url),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: .8),
                  Colors.black.withValues(alpha: .1),
                ],
                stops: [.1, .9],
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.feed.category.title,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(color: Colors.white),
                ),
                Text(
                  relativeDate(context, entry.date),
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
