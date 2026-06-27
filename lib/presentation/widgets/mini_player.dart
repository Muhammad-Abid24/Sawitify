import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sawitify/presentation/states/new_music_service.dart';
import 'package:sawitify/presentation/widgets/auto_marque.dart';

import '../../core/theme/app_theme.dart';
import '../../data/service/music_service/music_service.dart';
import '../pages/player_page.dart';
import 'youtube_thumbnail.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  String videoId = '';
  void _navigateToPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) {
        return PlayerPage(videoId: videoId);
      },
    );
  }

  Future<void> _togglePlayPause() async {
    await MusicService.instance.togglePlayPause();
  }

  Future<void> _skipToNext() async {
    await MusicService.instance.next();
  }

  bool _isImageLoading = false;
  String? _lastVideoId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicService.instance,
      builder: (context, _) {
        final service = MusicService.instance;

        final track = service.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        if (_lastVideoId != track.videoId) {
          _lastVideoId = track.videoId;

          _isImageLoading = true;
        }

        videoId = track.videoId;

        return GestureDetector(
          onTap: service.loadingTrack ? null : _navigateToPlayer,
          child: Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      StreamBuilder<PlayerState>(
                        stream: MusicService.instance.player.playerStateStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;

                          if (isPlaying && _isImageLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;

                              setState(() {
                                _isImageLoading = false;
                              });
                            });
                          }

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              YoutubeThumbnail(
                                key: ValueKey(videoId),
                                videoId: videoId,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(30),
                              ),

                              if (_isImageLoading)
                                Container(
                                  width: 45,
                                  height: 45,

                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(30),
                                  ),

                                  child: const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            autoMarquee(
                              text: track.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              height: 20,
                            ),
                            autoMarquee(
                              text: track.artist,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              height: 15,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _togglePlayPause,
                          icon: StreamBuilder<PlayerState>(
                            stream:
                                MusicService.instance.player.playerStateStream,
                            builder: (context, snapshot) {
                              final state = snapshot.data;

                              final isPlaying = state?.playing ?? false;

                              final completed =
                                  state?.processingState ==
                                  ProcessingState.completed;

                              return Icon(
                                (isPlaying && !completed)
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: AppColors.primary,
                                size: 24,
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _skipToNext,
                          icon: Icon(
                            Icons.skip_next,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
