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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:relative_time/relative_time.dart';

String dateFormat(dynamic date) {
  final t = parseDate(date);
  return DateFormat.yMd().add_jm().format(t);
}

String relativeDate(BuildContext context, dynamic date) {
  final t = parseDate(date);
  return t.relativeTime(context);
}

DateTime parseDate(dynamic date) {
  return ((date is String)
          ? DateTime.parse(date)
          : (date is DateTime)
          ? date
          : DateTime.parse(date.toString()))
      .toLocal();
}

String inHoursMinutes(Duration d) {
  final mins = d.inMinutes.remainder(60);
  return (d.inHours > 0 && mins > 0)
      ? '${d.inHours}h ${mins}m'
      : (d.inHours > 0)
      ? '${d.inHours}h'
      : '${mins}m';
}
