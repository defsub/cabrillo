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

// Originally based on just_audio example code.

import 'package:audio_service/audio_service.dart';
import 'package:cabrillo/cabrillo.dart';
import 'package:cabrillo/date.dart';
import 'package:cabrillo/player/player.dart';
import 'package:cabrillo/util.dart';
import 'package:cabrillo/widget/empty.dart';
import 'package:cabrillo/widget/image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'slider.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({super.key});

  @override
  PlayerWidgetState createState() => PlayerWidgetState();
}

class PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.black),
    );
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    // _handler.player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      // _handler.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    if (state.isEmpty) {
      return EmptyWidget();
    }
    final entry = state.entry;
    if (entry == null) {
      return EmptyWidget();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            spacing: 6,
            children: [
              feedIcon(context, entry.feed),
              Text(
                merge([relativeDate(context, entry.publishedAt), entry.author]),
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _playPauseButton(context, iconSize: 24),
              Expanded(child: _seekBar(context)),
              _speedButton(context),
            ],
          ),
        ],
      ),
    );
  }
}

class PlaybackData {
  PlaybackState playbackState;
  MediaItem? mediaItem;
  Duration position;

  PlaybackData(this.playbackState, this.mediaItem, this.position);
}

Widget _seekBar(BuildContext context) {
  final playerService = context.playerService;

  final playbackStream =
      Rx.combineLatest3<PlaybackState, MediaItem?, Duration, PlaybackData>(
        playerService.playbackState,
        playerService.mediaItem,
        playerService.positionStream,
        (playbackState, mediaItem, position) =>
            PlaybackData(playbackState, mediaItem, position),
      );

  return StreamBuilder<PlaybackData>(
    stream: playbackStream,
    builder: (context, snapshot) {
      final playbackData = snapshot.data;
      return SeekBar(
        duration: playbackData?.mediaItem?.duration ?? Duration.zero,
        position: playbackData?.position ?? Duration.zero,
        bufferedPosition:
            playbackData?.playbackState.bufferedPosition ?? Duration.zero,
        onChangeEnd: (value) {
          playerService.seek(value);
          context.player.update(value.inSeconds);
        },
      );
    },
  );
}

// Widget _volumeButton(BuildContext context, PlayerHandler handler) {
//   return IconButton(
//     icon: const Icon(Icons.volume_up),
//     onPressed: () {
//       showSliderDialog(
//         context: context,
//         title: "Adjust volume",
//         divisions: 10,
//         min: 0.0,
//         max: 1.0,
//         value: handler.player.volume,
//         stream: handler.player.volumeStream,
//         onChanged: handler.player.setVolume,
//       );
//     },
//   );
// }

Widget _playPauseButton(BuildContext context, {double? iconSize = 48}) {
  final playerService = context.playerService;

  return StreamBuilder<PlaybackState>(
    stream: playerService.playbackState,
    builder: (context, snapshot) {
      final playerState = snapshot.data;
      final processingState = playerState?.processingState;
      final playing = playerState?.playing;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          width: iconSize,
          height: iconSize,
          child: const CircularProgressIndicator(),
        );
      } else if (playing != true) {
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          iconSize: iconSize,
          onPressed: playerService.play,
        );
      } else if (processingState != AudioProcessingState.completed) {
        return IconButton(
          icon: const Icon(Icons.pause),
          iconSize: iconSize,
          onPressed: () {
            playerService.pause();
            context.player.update(
              playerService.playbackState.value.position.inSeconds,
            );
          },
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.replay),
          iconSize: iconSize,
          onPressed: () => playerService.seek(Duration.zero),
        );
      }
    },
  );
}

Widget _speedButton(BuildContext context) {
  final playerService = context.playerService;

  return StreamBuilder<double>(
    stream: playerService.speedStream,
    builder:
        (context, snapshot) => IconButton(
          icon: Text(
            "${snapshot.data?.toStringAsFixed(1)}x",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust speed",
              divisions: 10,
              min: 0.5,
              max: 1.5,
              value: playerService.playbackState.value.speed,
              stream: playerService.speedStream,
              onChanged: playerService.setSpeed,
            );
          },
        ),
  );
}
