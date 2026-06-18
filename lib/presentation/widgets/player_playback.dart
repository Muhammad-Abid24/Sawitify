import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../states/new_music_service.dart';

class PlaybackControls extends StatefulWidget {
  const PlaybackControls({
    super.key
  });

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {

  @override
  Widget build(BuildContext context) {

    final width =
        MediaQuery.sizeOf(context).width;

    final isTablet = width > 700;

    final iconSize =
    isTablet ? 54.0 : 40.0;

    final playSize =
    isTablet ? 82.0 : 55.0;

    final bgPlaySize =
    isTablet ? 130.0 : 70.0;


    Future<void> skipToNext() async {
      await NewMusicService.instance
          .next();
    }

    Future<void> skipToPrevious() async {
      await NewMusicService.instance
          .previous();
    }

    Future<void> togglePlayPause() async {

      final service =
          NewMusicService.instance;

      if (service.player.playing) {
        await service.pause();
      } else {
        await service.play();
      }
    }

    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceEvenly,
      children: [

        AnimatedBuilder(
          animation: NewMusicService.instance,
          builder: (context, _) {

            final loading =
                NewMusicService
                    .instance
                    .loadingTrack;

            return Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: loading
                    ? null
                    : skipToPrevious,
                padding: EdgeInsets.zero,
                constraints:
                const BoxConstraints(
                  minWidth: 64,
                  minHeight: 64,
                ),
                icon: loading
                    ? const SizedBox(
                  width: 32,
                  height: 32,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            );
          },
        ),

        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Container(
              width: bgPlaySize,
              height: bgPlaySize,
              color: Colors.white.withOpacity(.12),
              child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: togglePlayPause,
                  icon: StreamBuilder<PlayerState>(
                    stream: NewMusicService.instance.player.playerStateStream,
                    builder: (context, snapshot) {

                      final state = snapshot.data;

                      final isPlaying =
                          state?.playing ?? false;

                      final completed =
                          state?.processingState ==
                              ProcessingState.completed;

                      return Icon(
                        (isPlaying && !completed)
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: AppColors.primary,
                        size: playSize,
                      );
                    },
                  )
              ),

            ),
          ),
        ),

        AnimatedBuilder(
          animation: NewMusicService.instance,
          builder: (context, _) {

            final loading =
                NewMusicService
                    .instance
                    .loadingTrack;

            return Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: loading
                    ? null
                    : skipToNext,
                padding: EdgeInsets.zero,
                constraints:
                const BoxConstraints(
                  minWidth: 64,
                  minHeight: 64,
                ),
                icon: loading
                    ? const SizedBox(
                  width: 32,
                  height: 32,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            );
          },
        )
      ],
    );
  }
}