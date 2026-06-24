import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sawitify/presentation/widgets/shimmer_playlist.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/model/track_model.dart';
import '../../data/model/playlist_model.dart';
import '../../data/repository/player_repository.dart';
import '../../data/repository/playlist_repository.dart';
import '../../data/service/music_service/music_service.dart';
import '../widgets/circle_button.dart';
import '../widgets/mini_player.dart';
import '../widgets/my_form.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    required this.browseId,
    required this.title,
    required this.subTitle,
    required this.thumbnail,
  });

  final String browseId;
  final String title;
  final String subTitle;
  final String thumbnail;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? errorMessage;

  PlaylistResponse? playlist;

  late final PlayerRepository playerRepository;
  final searchController = TextEditingController();
  List<TrackModel> _filteredTracks = [];

  List<TrackModel> get serviceTracks {
    if (playlist == null) return [];

    return playlist!.tracks.map((e) {
      return TrackModel(
        title: e.title,
        artist: e.artist,
        videoId: e.videoId,
        thumbnail: e.thumbnail,
        duration: e.duration, // sesuaikan
      );
    }).toList();
  }

  int _getOriginalIndex(TrackModel track) {
    return serviceTracks.indexWhere((e) => e.videoId == track.videoId);
  }

  @override
  void initState() {
    super.initState();
    playerRepository = PlayerRepository(ApiClient());
    loadPlaylist();

    searchController.addListener(_onSearchChanged);

    _playController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _playScale = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(
        parent: _playController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _playController.dispose();
    super.dispose();
  }

  late final AnimationController _playController;
  late final Animation<double> _playScale;
  Future<void> _animatePlayButton() async {
    await _playController.forward();

    if (!mounted) return;

    await _playController.reverse();

    _playPlaylistFromStart();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim().toLowerCase();

    if (playlist == null) return;

    setState(() {
      if (query.isEmpty) {
        _filteredTracks = serviceTracks;
        return;
      }

      _filteredTracks = serviceTracks.where((track) {
        return track.title.toLowerCase().contains(query) ||
            track.artist.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _playPlaylistFromStart() async {
    final tracks = serviceTracks;

    if (tracks.isEmpty) {
      return;
    }

    final service = MusicService.instance;

    await service.setPlaylist(playlist: tracks, startIndex: 0);

    await service.playTrack(0);
  }

  Future<void> _playPlaylistShuffle() async {
    final tracks = serviceTracks;

    if (tracks.isEmpty) {
      return;
    }

    final startIndex = Random().nextInt(tracks.length);
    final service = MusicService.instance;

    await service.setPlaylist(playlist: tracks, startIndex: startIndex);

    await service.playTrack(startIndex);
  }

  Future<void> loadPlaylist() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final repository = PlaylistRepository(ApiClient().dioBrowse);

      final response = await repository.getPlaylistDetail(widget.browseId);

      debugPrint('PLAYLIST TITLE = ${response.title}');

      debugPrint('TRACK COUNT = ${response.tracks.length}');

      if (!mounted) return;

      setState(() {
        playlist = response;
        _filteredTracks = serviceTracks;
        _isLoading = false;
      });

      // Preload stream URLs untuk semua lagu di playlist
      if (response.tracks.isNotEmpty) {
        final videoIds = response.tracks.map((track) => track.videoId).toList();
        debugPrint('🔄 Starting preload for ${videoIds.length} tracks...');
      }
    } catch (e) {
      debugPrint('PLAYLIST ERROR: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 700;

    final hdThumbnail = widget.thumbnail.replaceAll(
      RegExp(r'=w\d+-h\d+.*'),
      '=w1000-h1000',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        await precacheImage(NetworkImage(hdThumbnail), context);

        debugPrint('✅ HD Thumbnail Cached');
      } catch (e) {
        debugPrint('❌ Thumbnail Cache Error: $e');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// BACKGROUND ARTWORK
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: hdThumbnail,

              imageBuilder: (context, imageProvider) {
                return Image(image: imageProvider, fit: BoxFit.cover);
              },

              placeholder: (context, url) {
                return OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.60,
                    child: Image.network(
                      widget.thumbnail,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                );
              },

              errorWidget: (context, url, error) {
                return OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.60,
                    child: Image.network(
                      widget.thumbnail,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                );
              },
            ),
          ),

          /// OVERLAY GRADIENT UTAMA
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .35, .65, 1],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .15),
                    Colors.black.withValues(alpha: .6),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          /// CONTENT
          RefreshIndicator(
            onRefresh: () async {
              await loadPlaylist();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                /// AREA ARTWORK
                SliverToBoxAdapter(child: SizedBox(height: size.height * .22)),

                /// TITLE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40 : 20,
                      vertical: 50,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _capitalize(widget.title),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 40 : 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${_filteredTracks.length} Tracks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 25 : 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),

                /// GRADIENT AREA (PLAY + SUBTITLE + LIST)
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        /// PLAY + SUBTITLE TETAP PAKAI GRADIENT
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black12,
                                Colors.black45,
                                Colors.black87,
                                Colors.black,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 40 : 20,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),

                                /// PLAY ROW
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Row(
                                    children: [
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),

                                      const SizedBox(width: 20),

                                      Expanded(
                                        child: SizedBox(
                                          height: isTablet ? 64 : 50,
                                          child: ElevatedButton(
                                            onPressed: null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: const StadiumBorder(),
                                            ),
                                            child: const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 20),

                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    widget.subTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isTablet ? 18 : 14,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),

                        /// SHIMMER TERPISAH
                        Container(
                          color: Colors.black,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),

                              ...List.generate(
                                11,
                                (_) => ShimmerPlaylist(isTablet: isTablet),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black12,
                            Colors.black45,
                            Colors.black45,
                            Colors.black87,
                            Colors.black87,
                            Colors.black87,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 15,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            /// PLAY ROW
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleButton(
                                    icon: Icons.shuffle,
                                    onTap: _playPlaylistShuffle,
                                  ),

                                  const SizedBox(width: 20),

                                  Expanded(
                                    child: SizedBox(
                                      height: isTablet ? 64 : 50,

                                      child: ScaleTransition(
                                        scale: _playScale,

                                        child: ElevatedButton(
                                          onPressed: _animatePlayButton,

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,

                                            shape: const StadiumBorder(),
                                          ),

                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 25,
                                              ),

                                              SizedBox(width: 5),

                                              Text(
                                                "Play",

                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  CircleButton(icon: Icons.add),
                                ],
                              ),
                            ),

                            const SizedBox(height: 23),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.subTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isTablet ? 18 : 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            ...List.generate(_filteredTracks.length, (index) {
                              final track = _filteredTracks[index];

                              return _SongTile(
                                track: track,
                                index: index,
                                isTablet: isTablet,
                              );
                            }),

                            const SizedBox(height: 190),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// TOP BAR OVERLAY
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),

                const Spacer(),

                CircleButton(
                  icon: Icons.share_outlined,
                  onTap: () => Navigator.pop(context),
                ),

                const SizedBox(width: 12),

                CircleButton(
                  icon: Icons.more_horiz,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Positioned(left: 0, right: 0, bottom: 105, child: MiniPlayer()),

          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: MyForm(
              controller: searchController,
              capitalize: TextCapitalization.none,
              hintText: 'Artist and Songs in playlist',
              prefixIcon: Icons.search,
            ),
          ),
        ],
      ),
    );
  }

  /*static Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            width: 48,
            height: 48,
            color: Colors.white.withValues(alpha: .12),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }*/

  /*static Widget _circleAction({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }*/
}

class _SongTile extends StatelessWidget {
  final TrackModel track;
  final int index;
  final bool isTablet;

  const _SongTile({
    required this.track,
    required this.index,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,

          child: InkWell(
            borderRadius: BorderRadius.circular(12),

            onTap: () async {
              try {
                final pageState = context
                    .findAncestorStateOfType<_PlaylistPageState>()!;

                debugPrint('PAGE STATE = $pageState');

                final tracks = pageState.serviceTracks;

                final originalIndex = pageState._getOriginalIndex(track);

                debugPrint('Tapped = ${track.title}');

                debugPrint('Tapped id = ${track.videoId}');

                debugPrint('Original index = $originalIndex');

                debugPrint('Track at index = ${tracks[originalIndex].title}');

                debugPrint('Video at index = ${tracks[originalIndex].videoId}');

                if (!context.mounted) return;

                await MusicService.instance.setPlaylist(
                  playlist: tracks,
                  startIndex: originalIndex,
                  playlistName: pageState.widget.title,
                );

                await MusicService.instance.playTrack(originalIndex);
              } catch (e) {
                debugPrint('PLAYER ERROR = $e');

                if (!context.mounted) return;

                String errorMessage = 'Gagal memutar lagu';

                if (e.toString().contains('age-restricted')) {
                  errorMessage = 'Lagu ini dibatasi oleh usia.';
                } else if (e.toString().contains('region-locked')) {
                  errorMessage = 'Lagu tidak tersedia di wilayah Anda.';
                } else if (e.toString().contains('playable')) {
                  errorMessage = 'Lagu tidak dapat diputar.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },

            child: ListTile(
              dense: true,

              visualDensity: const VisualDensity(vertical: -1),

              minVerticalPadding: 0,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 7,
                vertical: 1,
              ),

              leading: ClipRRect(
                borderRadius: BorderRadius.circular(7),

                child: CachedNetworkImage(
                  imageUrl: track.thumbnail,
                  width: isTablet ? 70 : 45,
                  height: isTablet ? 70 : 45,
                  fit: BoxFit.cover,
                ),
              ),

              title: Text(
                track.title.length > 30
                    ? '${track.title.substring(0, 30)}...'
                    : track.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              subtitle: Text(
                track.artist,
                style: const TextStyle(color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              trailing: const Icon(Icons.more_horiz, color: Colors.white54),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(left: isTablet ? 118 : 70, right: 12),
          child: Divider(height: 1, thickness: .1, color: Colors.white),
        ),
      ],
    );
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
