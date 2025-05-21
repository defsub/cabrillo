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

import 'dart:convert';

import 'package:cabrillo/app/context.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:cabrillo/widget/empty.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget cachedImage(
  String url, {
  double? width,
  double? height,
  BoxFit? fit,
  Alignment? alignment,
}) {
  return CachedNetworkImage(
    width: width,
    height: height,
    fit: fit,
    imageUrl: url,
    alignment: alignment ?? Alignment.center,
    // progressIndicatorBuilder: (context, url, downloadProgress) =>
    //     CircularProgressIndicator(value: downloadProgress.progress),
    // placeholder: (context, url) => Icon(Icons.image),
    // errorWidget: (context, url, error) => Icon(Icons.error),
  );
}

Widget image(
  String url, {
  double? width,
  double? height,
  EdgeInsetsGeometry? padding,
}) {
  return Container(
    padding: padding,
    child: cachedImage(url, width: width, height: height, fit: BoxFit.cover),
  );
}

Widget mainImage(BuildContext context, String url) {
  return Container(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: GestureDetector(
      onTap: () => showImage(context, url),
      child: cachedImage(url),
    ),
  );
}

var iconCache = <int, Widget>{};

Widget feedIcon(
  BuildContext context,
  Feed feed, {
  double? width = 16,
  double? height,
}) {
  final icon = iconCache[feed.id];
  if (icon != null) {
    return icon;
  }
  final result = context.clientRepository.feedIcon(feed);
  return FutureBuilder<Favicon>(
    future: result,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        Widget result;
        final bytes = snapshot.data?.bytes;
        if (bytes == null) {
          result = Icon(Icons.rss_feed);
        } else {
          final mimeType = snapshot.data?.mimeType;
          if (mimeType == 'image/svg+xml') {
            final re = RegExp(r'(<svg[^>]*>.+?</svg>)');
            final s = utf8.decode(
              base64Decode(snapshot.data?.encodedData ?? ''),
            );
            final match = re.firstMatch(s);
            if (match != null) {
              result = SvgPicture.string(width: width, match[1] ?? '');
            } else {
              result = Icon(Icons.error);
            }
          } else {
            result = Image.memory(width: width, height: height, bytes);
          }
        }
        iconCache[feed.id] = result;
        return result;
      } else {
        return EmptyWidget();
      }
    },
  );
}

void showImage(BuildContext context, String url) {
  showImageViewer(context, CachedNetworkImageProvider(url));
}
