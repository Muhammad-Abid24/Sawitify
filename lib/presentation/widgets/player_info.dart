import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:sawitify/core/utils/audio_output.dart';
import 'package:sawitify/presentation/widgets/player_playback.dart';

import '../../core/theme/app_theme.dart';
import '../states/new_music_service.dart';
import 'auto_marque.dart';
import 'circle_button.dart';

class MusicInfoSection extends StatefulWidget {
  const MusicInfoSection({
    super.key,
    required this.title,
    required this.artist,
    required this.videoId,
  });

  final String title;
  final String artist;
  final String videoId;

  @override
  State<MusicInfoSection> createState() =>
      _MusicInfoSectionState();
}

class _MusicInfoSectionState
    extends State<MusicInfoSection> {

  @override
  void initState() {
    super.initState();

    _initializeVolume();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Column(
      children: [
        const SizedBox(
          height: 11,
        ),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  autoMarquee(
                    text: widget.title,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize:
                      size.height < 700
                          ? 30
                          : 23,
                      fontWeight:
                      FontWeight.w500,
                    ),
                    height: 30,
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  autoMarquee(
                    text: widget.artist,
                    style: TextStyle(
                      color: Colors.white.withAlpha(95),
                      fontSize:
                      size.height < 700
                          ? 28
                          : 19,
                      fontWeight:
                      FontWeight.w600,
                    ),
                    height: 25,
                  ),
                ],
              ),
            ),
            const SizedBox( width: 5),


            CircleButton(
              icon: Icons.star_outline,
              width: 40,
              height: 40,
            ),

            const SizedBox( width: 5),

            CircleButton(
              icon: Icons.more_horiz,
              width: 40,
              height: 40,
            ),
          ],
        ),

        const SizedBox(
          height: 22,
        ),

        StreamBuilder<Duration>(
          stream: NewMusicService
              .instance
              .player
              .positionStream,
          builder: (
              context,
              positionSnapshot,
              ) {
            final duration =
                NewMusicService
                    .instance
                    .trackDuration;

            final rawPosition =
                positionSnapshot.data ??
                    Duration.zero;

            final position =
            rawPosition > duration
                ? duration
                : rawPosition;

            final progress =
            duration.inMilliseconds <= 0
                ? 0.0
                : position
                .inMilliseconds /
                duration
                    .inMilliseconds;

            final safeProgress =
            progress.clamp(
              0.0,
              1.0,
            );

            return Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    _formatDuration(
                      position,
                    ),
                    style:
                    const TextStyle(
                      color: Colors.white70,
                        fontSize: 16
                    ),
                  ),
                ),

                Expanded(
                  child: _buildSeekBar(
                    safeProgress * 100,
                    duration,
                  ),
                ),

                SizedBox(
                  width: 50,
                  child: Text(
                    '-${_formatDuration(
                      (duration - position).isNegative
                          ? Duration.zero
                          : duration - position,
                    )}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(
          height: 20,
        ),

        const PlaybackControls(),

        const SizedBox(
          height: 20,
        ),

        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 200,
              ),

              transitionBuilder:
                  (child, animation) {

                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },

              child: Icon(
                _getVolumeIcon(),

                key: ValueKey(
                  _getVolumeIcon(),
                ),

                size: 25,

                color: Colors.white70,
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Expanded(
              child: _buildSeekerVolume(),
            ),

            const SizedBox(
              width: 15,
            ),

            const Icon(
              Icons.volume_up,
              size: 25,
              color: Colors.white70,
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
          children: [
            CircleButton(
              icon: Icons.lyrics,
            ),

            CircleButton(
              icon: Icons.speaker_group,
              onTap: () async {

                if (Platform.isIOS) {

                  await AudioOutput.show();

                  return;
                }

                final devices =
                await AudioOutput
                    .getDevices();

                if (!context.mounted) {
                  return;
                }

                _showAndroidBottomSheet(
                  context,

                  devices,
                );
              },
            ),


            CircleButton(
              icon: Icons.playlist_play,
            ),
          ],
        )
      ],
    );
  }

  bool _isSeeking = false;
  double? _dragProgress;
  Widget _buildSeekBar(
      double progress,
      Duration duration,
      ) {

    final value =
        _dragProgress ?? progress;

    return GestureDetector(

      behavior:
      HitTestBehavior.opaque,

      onTapDown: (details) {},

      child:
      TweenAnimationBuilder<double>(

        duration: const Duration(
          milliseconds: 180,
        ),

        curve: Curves.easeOutCubic,

        tween: Tween(

          begin: 1,

          end:
          _isSeeking

              ? 5

              : 2,

        ),

        builder:

            (
            context,
            scale,
            child,
            ) {

          return SizedBox(

            height: 40,

            child: SliderTheme(

              data:

              SliderTheme.of(context)

                  .copyWith(

                padding:
                EdgeInsets.zero,

                trackHeight:

                3 * scale,

                thumbShape:

                const RoundSliderThumbShape(
                  enabledThumbRadius: 0.01,
                ),

                overlayShape:

                SliderComponentShape.noOverlay,

                activeTrackColor:

                AppColors.primary,

                inactiveTrackColor:

                Colors.white24,

                thumbColor:

                Colors.transparent,

                overlayColor:

                Colors.transparent,

              ),

              child: Slider(

                min: 0,

                max: 100,

                value:

                value.clamp(
                  0,
                  100,
                ),

                onChangeStart: (_) {

                  setState(() {

                    _isSeeking =
                    true;

                  });
                },

                onChanged: (
                    value,
                    ) {

                  setState(() {

                    _dragProgress =
                        value;

                  });
                },

                onChangeEnd: (
                    value,
                    ) async {

                  setState(() {

                    _isSeeking =
                    false;

                  });

                  if (duration
                      .inMilliseconds <=
                      0) {

                    return;

                  }

                  final seekPosition =
                  Duration(

                    milliseconds:

                    (duration
                        .inMilliseconds *

                        value /

                        100)

                        .round(),

                  );

                  await NewMusicService
                      .instance
                      .player
                      .seek(
                    seekPosition,
                  );

                  setState(() {

                    _dragProgress =
                    null;

                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(
      Duration duration,
      ) {
    final minutes =
    duration.inMinutes
        .toString();

    final seconds =
    (duration.inSeconds % 60)
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$minutes:$seconds';
  }


  Future<void> _initializeVolume() async {

    final volume =
    await FlutterVolumeController.getVolume();

    if (!mounted) return;

    setState(() {

      _volume = volume!;

    });
  }

  double _volume = 0.5;
  double? _dragVolume;
  bool _isVolumeSeeking = false;
  Widget _buildSeekerVolume() {

    final value =
        (_dragVolume ?? _volume) * 100;

    return GestureDetector(

      behavior: HitTestBehavior.opaque,

      child: TweenAnimationBuilder<double>(

        duration: const Duration(
          milliseconds: 180,
        ),

        curve: Curves.easeOutCubic,

        tween: Tween(

          begin: 1,

          end:

          _isVolumeSeeking

              ? 5

              : 2,

        ),

        builder:

            (
            context,
            scale,
            child,
            ) {

          return SizedBox(

            height: 40,

            child: SliderTheme(

              data:

              SliderTheme.of(context)

                  .copyWith(

                padding:
                EdgeInsets.zero,

                trackHeight:

                3 * scale,

                thumbShape:

                const RoundSliderThumbShape(
                  enabledThumbRadius: 0.01,
                ),

                overlayShape:

                SliderComponentShape.noOverlay,

                activeTrackColor:

                Colors.white,

                inactiveTrackColor:

                Colors.white24,

                thumbColor:

                Colors.transparent,

                overlayColor:

                Colors.transparent,

              ),

              child: Slider(

                min: 0,

                max: 100,

                value:

                value.clamp(
                  0,
                  100,
                ),

                onChangeStart: (_) {

                  setState(() {

                    _isVolumeSeeking =
                    true;

                  });
                },

                onChanged: (
                    value,
                    ) async {

                  final volume =
                      value / 100;

                  setState(() {

                    _dragVolume =
                        volume;

                  });

                  await FlutterVolumeController
                      .setVolume(
                    volume,
                  );
                },

                onChangeEnd: (
                    value,
                    ) async {

                  final volume =
                      value / 100;

                  await FlutterVolumeController
                      .setVolume(
                    volume,
                  );

                  setState(() {

                    _volume =
                        volume;

                    _dragVolume =
                    null;

                    _isVolumeSeeking =
                    false;

                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getVolumeIcon() {

    final volume =
        _dragVolume ?? _volume;

    if (volume <= 0.01) {
      return Icons.volume_off_rounded;
    }

    if (volume <= 0.5) {
      return Icons.volume_down_rounded;
    }

    return Icons.volume_down_rounded;
  }
}


void _showAndroidBottomSheet(

    BuildContext context,

    List<dynamic> devices,

    ) {

  final device =
      devices.first;

  final isBluetooth =
  device['isBluetooth'] as bool;

  showModalBottomSheet(

    context: context,

    backgroundColor:

    const Color(
      0xFF1E1E1E,
    ),

    shape:

    const RoundedRectangleBorder(

      borderRadius:

      BorderRadius.vertical(

        top:
        Radius.circular(
          24,
        ),
      ),
    ),

    builder: (_) {

      return SafeArea(

        child: Padding(

          padding:

          const EdgeInsets.all(
            20,
          ),

          child: Column(

            mainAxisSize:

            MainAxisSize.min,

            children: [

              ListTile(

                leading: Icon(

                  isBluetooth

                      ? Icons.headphones

                      : Icons.phone_android,

                  color: Colors.white,
                ),

                title: Text(

                  device['name'],

                  style:

                  const TextStyle(

                    color:

                    Colors.white,

                    fontSize:
                    16,
                  ),
                ),
              ),

              const Divider(),

              ListTile(

                leading:

                const Icon(

                  Icons.bluetooth,

                  color:
                  Colors.blue,
                ),

                title:

                const Text(

                  'Hubungkan perangkat Bluetooth',

                  style:

                  TextStyle(

                    color:
                    Colors.white,
                  ),
                ),

                onTap: () async {

                  Navigator.pop(
                    context,
                  );

                  await AudioOutput
                      .openBluetoothSettings();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}