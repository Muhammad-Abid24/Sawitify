import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../data/service/music_service/music_service.dart';
import '../states/new_music_service.dart';
import 'circle_button.dart';

class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key});

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final isTablet = width > 700;

    final iconSize = isTablet ? 54.0 : 40.0;

    final bgPlaySize = isTablet ? 130.0 : 70.0;

    Future<void> skipToNext() async {
      await MusicService.instance.next();
    }

    Future<void> skipToPrevious() async {
      await MusicService.instance.previous();
    }

    Future<void> togglePlayPause() async {
      final service = MusicService.instance;

      if (service.player.playing) {
        await service.pause();
      } else {
        await service.play();
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AnimatedBuilder(
          animation: MusicService.instance,
          builder: (context, _) {
            final loading = MusicService.instance.loadingTrack;

            return Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: loading ? null : skipToPrevious,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
                icon: loading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
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

        StreamBuilder<PlayerState>(
          stream: MusicService.instance.player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;

            final isPlaying = state?.playing ?? false;

            final completed =
                state?.processingState == ProcessingState.completed;

            return (isPlaying && !completed)
                ? CircleButton(
                    icon: Icons.pause,
                    onTap: togglePlayPause,
                    height: bgPlaySize,
                    width: bgPlaySize,
                    sizeIcon: 50,
                    colorBg: AppColors.primary,
                    colorIcon: Colors.white,
                  )
                : CircleButton(
                    icon: Icons.play_arrow,
                    onTap: togglePlayPause,
                    height: bgPlaySize,
                    width: bgPlaySize,
                    sizeIcon: 50,
                    colorBg: AppColors.primary,
                    colorIcon: Colors.white,
                  );
          },
        ),

        AnimatedBuilder(
          animation: MusicService.instance,
          builder: (context, _) {
            final loading = MusicService.instance.loadingTrack;

            return Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: loading ? null : skipToNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
                icon: loading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
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
        ),
      ],
    );
  }
}
