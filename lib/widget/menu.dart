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
import 'package:cabrillo/seen/widget.dart';
import 'package:flutter/material.dart';

typedef MenuCallback = void Function(BuildContext);

class PopupItem {
  final Icon? icon;
  final String? title;
  final MenuCallback? onSelected;
  final bool divider;
  final String? subtitle;
  final Widget? trailing;

  bool get isDivider => divider;

  factory PopupItem.divider() => const PopupItem(null, '', null, divider: true);

  const PopupItem(
    this.icon,
    this.title,
    this.onSelected, {
    this.divider = false,
    this.subtitle,
    this.trailing,
  });

  PopupItem.reload(BuildContext context, MenuCallback onSelected)
    : this(
        const Icon(Icons.refresh_sharp),
        context.strings.refreshLabel,
        onSelected,
      );

  PopupItem.about(BuildContext context, MenuCallback onSelected)
    : this(
        const Icon(Icons.info_outline),
        context.strings.aboutLabel,
        onSelected,
      );

  PopupItem.share(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.share), context.strings.shareLabel, onSelected);

  PopupItem.openLink(BuildContext context, MenuCallback onSelected)
    : this(
        const Icon(Icons.open_in_new),
        context.strings.openLinkLabel,
        onSelected,
      );

  PopupItem.settings(BuildContext context, MenuCallback onSelected)
    : this(
        const Icon(Icons.settings),
        context.strings.settingsLabel,
        onSelected,
      );

  PopupItem.search(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.search), context.strings.searchLabel, onSelected);

  PopupItem.sortTitle(BuildContext context, MenuCallback onSelected)
    : this(
        const Icon(Icons.sort_by_alpha),
        context.strings.sortTitle,
        onSelected,
      );

  PopupItem.sortUnread(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.sort), context.strings.sortUnread, onSelected);

  PopupItem.sortNewest(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.sort), context.strings.sortNewest, onSelected);

  PopupItem.sortOldest(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.sort), context.strings.sortOldest, onSelected);

  PopupItem.markPageSeen(BuildContext context, MenuCallback onSelected)
    : this(seenIcon(true), context.strings.markPageReadLabel, onSelected);

  PopupItem.markSeen(BuildContext context, MenuCallback onSelected)
    : this(seenIcon(true), context.strings.markSeenLabel, onSelected);

  PopupItem.markListened(BuildContext context, MenuCallback onSelected)
    : this(seenIcon(true), context.strings.markListenedLabel, onSelected);

  PopupItem.clear(BuildContext context, MenuCallback onSelected)
    : this(const Icon(Icons.clear), context.strings.clearLabel, onSelected);
}

Widget popupMenu(BuildContext context, List<PopupItem> items, {Icon? icon}) {
  return PopupMenuButton<int>(
    icon: icon ?? const Icon(Icons.more_vert),
    itemBuilder: (_) {
      List<PopupMenuEntry<int>> entries = [];
      for (var index = 0; index < items.length; index++) {
        final subtitle = items[index].subtitle;
        if (items[index].isDivider) {
          entries.add(const PopupMenuDivider());
        } else {
          entries.add(
            PopupMenuItem<int>(
              value: index,
              child: ListTile(
                leading: items[index].icon,
                title: Text(items[index].title ?? 'no title'),
                subtitle: subtitle != null ? Text(subtitle) : null,
                minLeadingWidth: 10,
              ),
            ),
          );
        }
      }
      return entries;
    },
    onSelected: (index) {
      items[index].onSelected?.call(context);
    },
  );
}

void showPopupMenu(
  BuildContext context,
  RelativeRect position,
  List<PopupItem> items,
) async {
  List<PopupMenuEntry<int>> entries = [];
  for (var index = 0; index < items.length; index++) {
    if (items[index].isDivider) {
      entries.add(const PopupMenuDivider());
    } else {
      final subtitle = items[index].subtitle;
      entries.add(
        PopupMenuItem<int>(
          value: index,
          child: ListTile(
            leading: items[index].icon,
            title: Text(items[index].title ?? 'no title'),
            subtitle: subtitle != null ? Text(subtitle) : null,
            minLeadingWidth: 10,
          ),
        ),
      );
    }
  }
  final selected = await showMenu(
    context: context,
    position: position,
    items: entries,
  );
  if (selected != null) {
    if (!context.mounted) {
      return;
    }
    items[selected].onSelected?.call(context);
  }
}
