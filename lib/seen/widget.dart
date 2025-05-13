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

import 'seen.dart';

const _smallSize = 16.0;
const _regularSize = 20.0;

IconData seenIconData(bool seen) {
  return seen ? Icons.task_alt : Icons.circle_outlined;
}

Icon seenIcon(bool seen, {double? size}) {
  return Icon(seenIconData(seen), size: size ?? _regularSize);
}

Icon seenSmallIcon(bool seen) {
  return seenIcon(seen, size: _smallSize);
}

Widget seenIconButton(BuildContext context, Entry entry) {
  final seen = context.watch<SeenCubit>().state.contains(entry.id);
  return IconButton(
    onPressed: () {
      if (seen) {
        context.seen.remove(entry.id);
      } else {
        context.seen.add(entry.id);
      }
    },
    icon: seenIcon(seen),
  );
}

Widget seenSmallIconButton(BuildContext context, Entry entry) {
  final seen = context.watch<SeenCubit>().state.contains(entry.id);
  return SmallIconButton(
    onPressed: () {
      if (seen) {
        context.seen.remove(entry.id);
      } else {
        context.seen.add(entry.id);
      }
    },
    icon: seenSmallIcon(seen),
  );
}

Icon readSmallIcon() {
  return Icon(Icons.check_circle, size: _smallSize);
}

Icon readIcon() {
  return Icon(Icons.check_circle, size: _regularSize);
}
