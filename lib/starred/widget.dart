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
import 'package:cabrillo/widget/button.dart';
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
