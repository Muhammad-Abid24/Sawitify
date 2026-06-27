import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sawitify/core/network/response/home_response.dart';
import 'package:sawitify/data/model/artist_model.dart';
import 'package:sawitify/data/model/track_model.dart';
import 'package:sawitify/data/repository/artist/artist_repository.dart';
import 'package:sawitify/data/repository/playlist_repository.dart';
import 'package:sawitify/data/service/music_service/music_service.dart';
import 'package:sawitify/presentation/pages/playlist_page.dart';
import 'package:sawitify/presentation/widgets/album_card.dart';
import 'package:sawitify/presentation/widgets/shimmer_playlist.dart';
import 'package:sawitify/presentation/widgets/song_tiles.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/circle_button.dart';
import '../widgets/mini_player.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({
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
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    _loadArtist();

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
    super.initState();
  }

  @override
  void dispose() {
    _loadArtist();
    super.dispose();
  }

  bool _loading = true;

  final _repository = ArtistRepository(ApiClient());
  ArtistResponse? _artist;
  Future<void> _loadArtist() async {
    try {
      final result = await _repository.getArtist(widget.browseId);

      if (!mounted) return;

      setState(() {
        _artist = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildTopSongs(bool isTablet) {
    if (_artist == null) {
      return const SizedBox();
    }

    final tracks = _artist!.topSongs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Top Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -40),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracks.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.white.withOpacity(.08)),
            itemBuilder: (_, index) {
              final track = tracks[index];

              return SongTiles(
                track: track,
                index: index,
                isTablet: isTablet,
                playlistName: _artist!.artist.name,
                playlist: tracks,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbums() {
    if (_artist == null || _artist!.albums.isEmpty) {
      return const SizedBox();
    }

    final albums = _artist!.albums;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(200),
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                "Albums",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: albums.length,
            itemBuilder: (_, index) {
              final album = albums[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 135,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      debugPrint("CLICK ALBUM");
                      debugPrint("TITLE     : ${album.title}");
                      debugPrint("BROWSE ID : ${album.browseId}");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistPage(
                            browseId: album.browseId,
                            title: album.title,
                            subTitle: album.year,
                            thumbnail: album.thumbnail,
                          ),
                        ),
                      );
                    },
                    child: AlbumCard(
                      image: album.thumbnail,
                      title: album.title,
                      artist: album.year,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingle() {
    if (_artist == null || _artist!.singles.isEmpty) {
      return const SizedBox();
    }

    final single = _artist!.singles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(200),
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                "Singles & Eps",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: single.length,
            itemBuilder: (_, index) {
              final album = single[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 135,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      debugPrint("CLICK ALBUM");
                      debugPrint("TITLE     : ${album.title}");
                      debugPrint("BROWSE ID : ${album.browseId}");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistPage(
                            browseId: album.browseId,
                            title: album.title,
                            subTitle: album.year,
                            thumbnail: album.thumbnail,
                          ),
                        ),
                      );
                    },
                    child: AlbumCard(
                      image: album.thumbnail,
                      title: album.title,
                      artist: album.year,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  late final AnimationController _playController;
  late final Animation<double> _playScale;
  Future<void> _animatePlayButton() async {
    await _playController.forward();

    if (!mounted) return;

    await _playController.reverse();

    //_playPlaylistFromStart();
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
              await _loadArtist();
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
                        ),

                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),

                /// GRADIENT AREA (PLAY + SUBTITLE + LIST)
                if (_loading)
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
                                  // CircleButton(
                                  //   icon: Icons.shuffle,
                                  //   onTap: _playPlaylistShuffle,
                                  // ),
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

                            _buildTopSongs(isTablet),

                            Transform.translate(
                              offset: const Offset(0, -40),
                              child: _buildAlbums(),
                            ),

                            Transform.translate(
                              offset: const Offset(0, -40),
                              child: _buildSingle(),
                            ),

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
                  colorIcon: AppColors.primary,
                  onTap: () => Navigator.pop(context),
                ),

                const Spacer(),

                CircleButton(
                  icon: Icons.ios_share,
                  colorIcon: AppColors.primary,
                  onTap: () => Navigator.pop(context),
                ),

                const SizedBox(width: 12),

                CircleButton(
                  icon: Icons.more_horiz,
                  colorIcon: AppColors.primary,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Positioned(left: 0, right: 0, bottom: 30, child: MiniPlayer()),
        ],
      ),
    );
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
