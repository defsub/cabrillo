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

import 'package:audio_service/audio_service.dart';
import 'package:cabrillo/miniflux/model.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import 'handler.dart';

extension on Entry {
  MediaItem? toMediaItem() {
    final uri = audioUri;
    if (uri == null) {
      return null;
    }
    return MediaItem(
      id: uri.toString(),
      title: title,
      artist: author,
      // duration: Duration(minutes: readingTime),
      // artUri: uri,
    );
  }
}

class PlayerService {
  late PlayerHandler _handler;
  final Logger log = Logger();

  Future<void> init() async {
    try {
      _handler = await PlayerHandler.create();
    } catch (e, stack) {
      log.e('PlayerHandler.create', error: e, stackTrace: stack);
    }
  }

  Future<void> playEntry(Entry entry, {int? position}) async {
    final item = entry.toMediaItem();
    if (item != null) {
      _handler.mediaItem.add(item);
      await _handler.playMediaItem(item);
      await _handler.seek(Duration(seconds: position ?? 0));
    }
  }

  BehaviorSubject<PlaybackState> get playbackState => _handler.playbackState;

  BehaviorSubject<MediaItem?> get mediaItem => _handler.mediaItem;

  Stream<double> get speedStream => _handler.player.speedStream;

  Stream<Duration> get positionStream => _handler.player.positionStream;

  Future<void> play() => _handler.play();

  Future<void> pause() => _handler.pause();

  Future<void> stop() => _handler.stop();

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);
}
