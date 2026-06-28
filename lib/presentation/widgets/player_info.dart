import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:sawitify/core/utils/audio_output.dart';
import 'package:sawitify/presentation/widgets/player_playback.dart';
import 'package:sawitify/presentation/widgets/rectangle_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../core/theme/app_theme.dart';
import '../../data/model/track_model.dart';
import '../../data/service/music_service/music_service.dart';
import 'auto_marque.dart';
import 'circle_button.dart';

class MusicInfoSection extends StatefulWidget {
  const MusicInfoSection({
    super.key,
    required this.title,
    required this.artist,
    required this.videoId,
    required this.playlistName,
  });

  final String title;
  final String artist;
  final String videoId;
  final String playlistName;

  @override
  State<MusicInfoSection> createState() => _MusicInfoSectionState();
}

class _MusicInfoSectionState extends State<MusicInfoSection> {
  @override
  void initState() {
    super.initState();

    _initializeVolume();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final music = MusicService.instance;

    return Column(
      children: [
        const SizedBox(height: 11),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  autoMarquee(
                    text: widget.title,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: size.height < 700 ? 30 : 23,
                      fontWeight: FontWeight.w500,
                    ),
                    height: 30,
                  ),

                  const SizedBox(height: 3),

                  autoMarquee(
                    text: widget.artist,
                    style: TextStyle(
                      color: Colors.white.withAlpha(95),
                      fontSize: size.height < 700 ? 28 : 19,
                      fontWeight: FontWeight.w600,
                    ),
                    height: 25,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),

            CircleButton(icon: Icons.more_horiz),
          ],
        ),

        const SizedBox(height: 22),

        StreamBuilder<Duration>(
          stream: MusicService.instance.player.positionStream,
          builder: (context, positionSnapshot) {
            final duration = MusicService.instance.trackDuration;

            final rawPosition = positionSnapshot.data ?? Duration.zero;

            final position = rawPosition > duration ? duration : rawPosition;

            final progress = duration.inMilliseconds <= 0
                ? 0.0
                : position.inMilliseconds / duration.inMilliseconds;

            final safeProgress = progress.clamp(0.0, 1.0);

            return Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),

                Expanded(child: _buildSeekBar(safeProgress * 100, duration)),

                SizedBox(
                  width: 50,
                  child: Text(
                    '-${_formatDuration((duration - position).isNegative ? Duration.zero : duration - position)}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        const PlaybackControls(),

        const SizedBox(height: 20),

        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),

              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },

              child: Icon(
                _getVolumeIcon(),

                key: ValueKey(_getVolumeIcon()),

                size: 25,

                color: Colors.white70,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(child: _buildSeekerVolume()),

            const SizedBox(width: 15),

            const Icon(Icons.volume_up, size: 25, color: Colors.white70),
          ],
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: music.hasSleepTimer
              ? InkWell(
                  key: const ValueKey("sleep_timer"),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showSleepTimer(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      "Timer Running (${music.remainingSleepTimeLabel})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey("no_sleep_timer")),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleButton(icon: Icons.lyrics),

            CircleButton(
              icon: Icons.cast,
              onTap: () async {
                if (Platform.isIOS) {
                  await AudioOutput.show();

                  return;
                }

                final devices = await AudioOutput.getDevices();

                if (!context.mounted) {
                  return;
                }

                _showAndroidSpeakerBottomSheet(context, devices);
              },
            ),

            CircleButton(
              icon: Icons.playlist_play,
              onTap: () => _showListQueue(context, widget.playlistName),
            ),
          ],
        ),
      ],
    );
  }

  bool _isSeeking = false;
  double? _dragProgress;
  Widget _buildSeekBar(double progress, Duration duration) {
    final value = _dragProgress ?? progress;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (details) {},

      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 180),

        curve: Curves.easeOutCubic,

        tween: Tween(begin: 1, end: _isSeeking ? 5 : 2),

        builder: (context, scale, child) {
          return SizedBox(
            height: 40,

            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                padding: EdgeInsets.zero,

                trackHeight: 3 * scale,

                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 0.01,
                ),

                overlayShape: SliderComponentShape.noOverlay,

                activeTrackColor: AppColors.primary,

                inactiveTrackColor: Colors.white24,

                thumbColor: Colors.transparent,

                overlayColor: Colors.transparent,
              ),

              child: Slider(
                min: 0,

                max: 100,

                value: value.clamp(0, 100),

                onChangeStart: (_) {
                  setState(() {
                    _isSeeking = true;
                  });
                },

                onChanged: (value) {
                  setState(() {
                    _dragProgress = value;
                  });
                },

                onChangeEnd: (value) async {
                  setState(() {
                    _isSeeking = false;
                  });

                  if (duration.inMilliseconds <= 0) {
                    return;
                  }

                  final seekPosition = Duration(
                    milliseconds: (duration.inMilliseconds * value / 100)
                        .round(),
                  );

                  await MusicService.instance.player.seek(seekPosition);

                  setState(() {
                    _dragProgress = null;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();

    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Future<void> _initializeVolume() async {
    final volume = await FlutterVolumeController.getVolume();

    if (!mounted) return;

    setState(() {
      _volume = volume!;
    });
  }

  double _volume = 0.5;
  double? _dragVolume;
  bool _isVolumeSeeking = false;
  Widget _buildSeekerVolume() {
    final value = (_dragVolume ?? _volume) * 100;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 180),

        curve: Curves.easeOutCubic,

        tween: Tween(begin: 1, end: _isVolumeSeeking ? 5 : 2),

        builder: (context, scale, child) {
          return SizedBox(
            height: 40,

            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                padding: EdgeInsets.zero,

                trackHeight: 3 * scale,

                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 0.01,
                ),

                overlayShape: SliderComponentShape.noOverlay,

                activeTrackColor: Colors.white,

                inactiveTrackColor: Colors.white24,

                thumbColor: Colors.transparent,

                overlayColor: Colors.transparent,
              ),

              child: Slider(
                min: 0,

                max: 100,

                value: value.clamp(0, 100),

                onChangeStart: (_) {
                  setState(() {
                    _isVolumeSeeking = true;
                  });
                },

                onChanged: (value) async {
                  final volume = value / 100;

                  setState(() {
                    _dragVolume = volume;
                  });

                  await FlutterVolumeController.setVolume(volume);
                },

                onChangeEnd: (value) async {
                  final volume = value / 100;

                  await FlutterVolumeController.setVolume(volume);

                  setState(() {
                    _volume = volume;

                    _dragVolume = null;

                    _isVolumeSeeking = false;
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
    final volume = _dragVolume ?? _volume;

    if (volume <= 0.01) {
      return Icons.volume_off_rounded;
    }

    if (volume <= 0.5) {
      return Icons.volume_down_rounded;
    }

    return Icons.volume_down_rounded;
  }
}

void _showAndroidSpeakerBottomSheet(
  BuildContext context,
  List<dynamic> devices,
) {
  final device = devices.first;

  final isBluetooth = device['isBluetooth'] as bool;

  showModalBottomSheet(
    context: context,

    backgroundColor: const Color(0xFF1E1E1E),

    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),

    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: Icon(
                  isBluetooth ? Icons.headphones : Icons.phone_android,

                  color: Colors.white,
                ),

                title: Text(
                  device['name'],

                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.blue),

                title: const Text(
                  'Hubungkan perangkat Bluetooth',

                  style: TextStyle(color: Colors.white),
                ),

                onTap: () async {
                  Navigator.pop(context);

                  await AudioOutput.openBluetoothSettings();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showListQueue(BuildContext context, String playlistName) {
  final music = MusicService.instance;

  showModalBottomSheet(
    context: context,

    isScrollControlled: true,

    backgroundColor: Colors.transparent,

    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,

        minChildSize: 0.65,

        maxChildSize: 0.85,

        expand: false,

        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.black,

              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),

            child: SafeArea(
              top: false,

              child: AnimatedBuilder(
                animation: music,

                builder: (_, __) {
                  final queue = music.queueTracks;

                  if (queue.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 48,

                        height: 5,

                        decoration: BoxDecoration(
                          color: AppColors.primary,

                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Continue Playing',

                        style: TextStyle(
                          fontSize: 17,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'From $playlistName',

                        style: const TextStyle(
                          fontSize: 14,

                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          RectangleButton(
                            icon: Icons.repeat,
                            width: 75,
                            height: 40,
                          ),

                          AnimatedBuilder(
                            animation: MusicService.instance,
                            builder: (_, __) {
                              final music = MusicService.instance;

                              return RectangleButton(
                                icon: Icons.timer,
                                color: music.hasSleepTimer
                                    ? AppColors.primary
                                    : Colors.white,
                                width: 75,
                                height: 40,
                                onTap: () => _showSleepTimer(context),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // =====================
                      // NOW PLAYING
                      // =====================
                      Material(
                        color: AppColors.background1,

                        child: _buildQueueTile(
                          context: context,

                          music: music,

                          track: queue.first,

                          index: 0,

                          playing: true,
                        ),
                      ),

                      const Divider(height: 1, color: Colors.white10),

                      // =====================
                      // LIST QUEUE
                      // =====================
                      Expanded(
                        child: ReorderableListView.builder(
                          scrollController: scrollController,

                          buildDefaultDragHandles: false,

                          itemCount: queue.length - 1,

                          onReorder: (oldIndex, newIndex) {
                            music.moveQueueItem(oldIndex + 1, newIndex + 1);
                          },

                          itemBuilder: (context, index) {
                            final realIndex = index + 1;

                            final track = queue[realIndex];

                            return Material(
                              key: ValueKey(track.videoId),

                              color: Colors.transparent,

                              child: _buildQueueTile(
                                context: context,

                                music: music,

                                track: track,

                                index: realIndex,

                                playing: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildQueueTile({
  required BuildContext context,

  required MusicService music,

  required TrackModel track,

  required int index,

  required bool playing,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),

    leading: SizedBox(
      width: 45,

      height: 45,

      child: Stack(
        alignment: Alignment.center,

        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),

            child: Image.network(
              track.thumbnail,

              width: 45,

              height: 45,

              fit: BoxFit.cover,

              errorBuilder: (_, __, ___) {
                return Container(
                  width: 45,

                  height: 45,

                  decoration: BoxDecoration(
                    color: Colors.white10,

                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: const Icon(Icons.album_rounded, color: Colors.white54),
                );
              },
            ),
          ),

          if (playing)
            Container(
              width: 45,

              height: 45,

              decoration: BoxDecoration(
                color: AppColors.background1.withAlpha(75),

                borderRadius: BorderRadius.circular(7),
              ),

              child: const Center(
                child: Icon(
                  Icons.graphic_eq,

                  size: 26,

                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    ),

    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        if (playing)
          const Text(
            'Now Playing',

            style: TextStyle(
              fontSize: 12,

              fontWeight: FontWeight.w600,

              color: AppColors.primary,
            ),
          ),

        playing
            ? autoMarquee(
                text: track.title,

                height: 20,

                style: const TextStyle(
                  color: Colors.white,

                  fontWeight: FontWeight.bold,

                  fontSize: 16,
                ),
              )
            : Text(
                track.title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,

                  fontWeight: FontWeight.w500,

                  fontSize: 16,
                ),
              ),

        playing
            ? autoMarquee(
                text: track.artist,

                height: 17,

                style: const TextStyle(color: Colors.white70, fontSize: 13),
              )
            : Text(
                track.artist,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
      ],
    ),

    trailing: index == 0
        ? GestureDetector(
            onTap: music.togglePlayPause,

            child: Container(
              width: 40,

              height: 40,

              decoration: const BoxDecoration(
                shape: BoxShape.circle,

                color: AppColors.primary,
              ),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),

                switchInCurve: Curves.easeOut,

                switchOutCurve: Curves.easeIn,

                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },

                child: Icon(
                  music.isPlaying ? Icons.pause : Icons.play_arrow,

                  key: ValueKey(music.isPlaying),

                  color: Colors.white,

                  size: 22,
                ),
              ),
            ),
          )
        : ReorderableDragStartListener(
            index: index - 1,

            child: const Icon(Icons.drag_indicator),
          ),
  );
}

void _showSleepTimer(BuildContext context) {
  final music = MusicService.instance;

  showModalBottomSheet(
    context: context,

    isScrollControlled: true,

    backgroundColor: Colors.transparent,

    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,

        minChildSize: 0.65,

        maxChildSize: 0.85,

        expand: false,

        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.black,

              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),

            child: SafeArea(
              top: false,

              child: AnimatedBuilder(
                animation: music,

                builder: (_, __) {
                  final queue = music.queueTracks;

                  if (queue.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 48,

                        height: 5,

                        decoration: BoxDecoration(
                          color: AppColors.primary,

                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Sleep Timer',

                        style: TextStyle(
                          fontSize: 17,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Divider(height: 1, color: Colors.white10),

                      // =====================
                      // LIST SLEEP TIMER
                      // =====================
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            _buildSleepTile(
                              title: "5 Minutes",
                              subtitle: "Stop music after 5 minutes",
                              icon: Icons.bedtime_rounded,
                              onTap: () async {
                                await music.startSleepTimer(
                                  const Duration(minutes: 5),
                                );
                                //if (context.mounted) Navigator.pop(context);
                              },
                            ),

                            _buildSleepTile(
                              title: "10 Minutes",
                              subtitle: "Stop music after 10 minutes",
                              icon: Icons.bedtime_rounded,
                              onTap: () async {
                                await music.startSleepTimer(
                                  const Duration(minutes: 10),
                                );
                                //if (context.mounted) Navigator.pop(context);
                              },
                            ),

                            _buildSleepTile(
                              title: "20 Minutes",
                              subtitle: "Stop music after 20 minutes",
                              icon: Icons.bedtime_rounded,
                              onTap: () async {
                                await music.startSleepTimer(
                                  const Duration(minutes: 20),
                                );
                                //if (context.mounted) Navigator.pop(context);
                              },
                            ),

                            _buildSleepTile(
                              title: "30 Minutes",
                              subtitle: "Stop music after 30 minutes",
                              icon: Icons.bedtime_rounded,
                              onTap: () async {
                                await music.startSleepTimer(
                                  const Duration(minutes: 30),
                                );
                                //if (context.mounted) Navigator.pop(context);
                              },
                            ),

                            _buildSleepTile(
                              title: "1 Hour",
                              subtitle: "Stop music after 1 hour",
                              icon: Icons.bedtime_rounded,
                              onTap: () async {
                                await music.startSleepTimer(
                                  const Duration(hours: 1),
                                );
                                //if (context.mounted) Navigator.pop(context);
                              },
                            ),

                            if (music.hasSleepTimer) ...[
                              const Divider(color: Colors.white10),

                              ListTile(
                                leading: const Icon(
                                  Icons.timer,
                                  color: AppColors.primary,
                                ),

                                title: Text(
                                  "Timer Running (${music.remainingSleepTimeLabel})",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                subtitle: const Text(
                                  "Tap to stop sleep timer",
                                  style: TextStyle(color: Colors.grey),
                                ),

                                trailing: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                ),

                                onTap: () async {
                                  await music.cancelSleepTimer();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildSleepTile({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );
}
