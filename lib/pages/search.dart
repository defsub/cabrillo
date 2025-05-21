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
import 'package:cabrillo/pages/page.dart';
import 'package:cabrillo/widget/menu.dart';
import 'package:flutter/material.dart';

import 'entry.dart';

class SearchWidget extends ClientPage<Entries> {
  final Feed? feed;
  final Category? category;
  final _query = StringBuffer();

  SearchWidget({super.key, this.feed, this.category})
    : super(value: Entries.empty());

  @override
  Future<void> load(BuildContext context, {Duration? ttl}) async {
    if (_query.isNotEmpty) {
      return context.miniflux.search(
        _query.toString(),
        ttl: Duration.zero,
        feed: feed,
        category: category,
      );
    }
  }

  @override
  Widget page(BuildContext context, Entries state) {
    final entries = state.entries;
    return Scaffold(
      appBar: AppBar(
        title: _SearchField((value) => _onSubmit(context, value)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          popupMenu(context, [
            PopupItem.reload(context, (_) => reloadPage(context)),
          ]),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: EntryListWidget(entries, feed: feed, category: category),
          ),
        ],
      ),
    );
  }

  void _onSubmit(BuildContext context, String value) {
    _query.clear();
    _query.write(value);
    load(context);
  }
}

class _SearchField extends StatefulWidget {
  final StringBuffer query = StringBuffer();
  final void Function(String) onSubmit;

  _SearchField(this.onSubmit);

  @override
  State createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autocorrect: true,
      // autofocus: true,
      decoration: InputDecoration(
        border: UnderlineInputBorder(),
        labelText: context.strings.searchLabel,
      ),
      onFieldSubmitted: (value) => widget.onSubmit(value),
      initialValue: widget.query.toString(),
    );
  }
}
