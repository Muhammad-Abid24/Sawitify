import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawitify/core/theme/app_theme.dart';
import 'package:sawitify/presentation/pages/playlist_page.dart';
import 'package:sawitify/presentation/widgets/mini_player.dart';

import '../../core/network/api_client.dart';
import '../../core/network/response/home_response.dart';
import '../../core/storage/session_manager.dart';
import '../../data/model/track_model.dart';
import '../../data/repository/playlist_repository.dart';
import '../../data/repository/home_repository.dart';
import '../states/new_music_service.dart';
import '../widgets/album_card.dart';
import 'new_playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     debugShowCheckedModeBanner: false,
  //     theme: ThemeData.dark(),
  //     home: const HomePageState(),
  //   );
  // }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  String photoUrl = "";

  List<Shelf> shelves = [];

  bool isLoading = true;

  String? errorMessage;

  String getShelfTitle(String title) {
    switch (true) {
      case true when title.contains("Favorit selamanya"):
        return "Playlist Favorit";

      case true when title.contains("Playlist trending komunitas"):
        return "Dari Komunitas";

      case true when title.contains("Hits Sepanjang Masa"):
        return "Lagu Legendaris";

        case true when title.contains("Hits Indonesia"):
        return "Hits Indonesia";

      default:
        return title;
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadHome();

    _scrollController.addListener(
      _updateScrollbar,
    );
  }



  @override
  void dispose() {

    _scrollController.dispose();

    super.dispose();
  }

  bool _showScrollbar = false;

  double _scrollProgress = 0;

  Timer? _scrollTimer;

  final ScrollController _scrollController =
  ScrollController();

  void _updateScrollbar() {

    if (!_scrollController.hasClients) {
      return;
    }

    final max =
        _scrollController.position.maxScrollExtent;

    if (max <= 0) {
      return;
    }

    final offset =
        _scrollController.offset;

    _scrollProgress =
        (offset / max)
            .clamp(0.0, 1.0);

    if (!_showScrollbar) {

      setState(() {
        _showScrollbar = true;
      });
    } else {

      setState(() {});
    }

    _scrollTimer?.cancel();

    _scrollTimer = Timer(

      const Duration(
        milliseconds: 800,
      ),

          () {

        if (!mounted) {
          return;
        }

        setState(() {
          _showScrollbar = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
          ),
        child: Container(
        color: Colors.black,
        child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
                  child: _buildHeader(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: const Center(
                  child: CircularProgressIndicator(),
                ),

              )
              ]
        )
      )
      );
    }


    if (errorMessage != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        child: Container(
          color: Colors.black,
          child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
                    child: _buildHeader(),
                  ),
                ),
                Center(
                    child: Text(errorMessage!),
                ),
              ]
          )
      )
      );
    }


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
        child: Stack(
          children: [
            // Background color fills entire screen
            Container(
              color: Colors.black,
            ),

            // Fixed Header (not scrollable)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(16, 55, 12, 9),
                child: _buildHeader(),
              ),
            ),

            // Scrollable content - starts below header, extends behind navbar
            Padding(
              padding: const EdgeInsets.only(
                top: 110,
              ),

              child: Stack(

                children: [

                  RefreshIndicator(

                    onRefresh: () async {
                      await loadHome();
                    },

                    child: CustomScrollView(

                      controller:
                      _scrollController,

                      physics:
                      const AlwaysScrollableScrollPhysics(),

                      slivers: [

                        SliverToBoxAdapter(

                          child: Padding(

                            padding:
                            const EdgeInsets.all(
                              16,
                            ),

                            child:
                            _buildCategories(),
                          ),
                        ),

                        SliverList(

                          delegate:
                          SliverChildBuilderDelegate(

                                (
                                context,
                                index,
                                ) {

                              return _buildShelf(
                                shelves[index],
                              );
                            },

                            childCount:
                            shelves.length,
                          ),
                        ),

                        const SliverToBoxAdapter(

                          child: SizedBox(
                            height: 150,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(

                    right: 0,

                    top: 20,

                    bottom: 160,

                    child: IgnorePointer(

                      child: AnimatedOpacity(

                        opacity:
                        _showScrollbar
                            ? 1
                            : 0,

                        duration:
                        const Duration(
                          milliseconds: 250,
                        ),

                        child: Align(

                          alignment: Alignment(

                            1,

                            -1 +
                                (_scrollProgress * 2),
                          ),

                          child: Container(

                            width: 5,

                            height: 55,

                            decoration:

                            BoxDecoration(

                              color:
                              AppColors.primary,

                              borderRadius:

                              BorderRadius.circular(
                                999,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating MiniPlayer (above navbar)
            // const Positioned(
            //   left: 0,
            //   right: 0,
            //   bottom: 100,
            //   child: MiniPlayer(),
            // ),

          ],
        )
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
       Image.asset(
      "assets/logo/ic_logo_horizontal.png",
      width: 150,
      height: 50,),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.cast),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      "All",
      "Music",
      "Events",
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: Text(
                categories[index],
              style: TextStyle(
                color: Colors.white
              ),
            ),
          );
        },
        separatorBuilder: (_, __) =>
        const SizedBox(width: 10),
        itemCount: categories.length,
      ),
    );
  }


  Widget _buildShelf(Shelf shelf) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
            mainAxisAlignment:
            MainAxisAlignment.start,
            children: [
              SizedBox(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 5,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                      BorderRadius.circular(200),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 5),

              Text(
                getShelfTitle(shelf.title),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ]
            )

          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              itemBuilder: (_, index) {
                final item =
                shelf.items[index];

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    right: 12,
                  ),
                  child: SizedBox(
                    width: 135,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        debugPrint(
                          'CLICK PLAYLIST: ${item.title}',
                        );

                        debugPrint(
                          'BROWSE ID: ${item.browseId}',
                        );

                        debugPrint('===================');
                        debugPrint('TITLE      : ${item.title}');
                        debugPrint('SUBTITLE   : ${item.subtitle}');
                        debugPrint('BROWSE ID  : ${item.browseId}');
                        debugPrint('THUMBNAIL  : ${item.thumbnail}');
                        debugPrint('===================');

                        final browseId = item.browseId;

                        if (browseId.startsWith('VL')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewPlaylistPage(
                                browseId: item.browseId,
                                title: item.title,
                                subTitle: item.subtitle,
                                thumbnail: item.thumbnail,
                              ),
                            ),
                          );
                          return;
                        }

                        if (browseId.startsWith('MPRE')) {

                          debugPrint(
                            'SINGLE/ALBUM => ${item.title}',
                          );

                          try {

                            final repository =
                            PlaylistRepository(
                              ApiClient().dioBrowse,
                            );

                            final response =
                            await repository
                                .getPlaylistDetail(
                              browseId,
                            );

                            if (response.tracks.isEmpty) {
                              return;
                            }

                            final tracks = List<TrackModel>.from(
                              response.tracks,
                            );

                            final artist =
                            item.subtitle.contains('•')
                                ? item.subtitle.split('•').last.trim()
                                : item.subtitle;

                            if (tracks.isEmpty) {
                              return;
                            }

                            /// Override metadata track pertama
                            tracks[0] = TrackModel(
                              title: item.title,
                              artist: artist,
                              videoId: tracks[0].videoId,
                              thumbnail: item.thumbnail,
                              duration: tracks[0].duration,
                            );

                            await NewMusicService.instance
                                .setPlaylist(
                              playlist: tracks,
                              startIndex: 0,
                            );

                            await NewMusicService.instance
                                .playTrack(0);

                          } catch (e) {

                            debugPrint(
                              'PLAY ALBUM ERROR: $e',
                            );
                          }
                        }


                      },
                      child: AlbumCard(
                        image: item.thumbnail,
                        title: item.title,
                        artist: item.subtitle,
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

  Future<void> loadUserName() async {
    final user = await SessionManager.getDataUSerLogin();
    if (mounted) {
      setState(() {
        userName = user['username'] ?? '';
        email = user['email'] ?? '';
        photoUrl = user['photo_url'] ?? '';
      });
      debugPrint('USERNAME : $userName');
      debugPrint('EMAIL : $email');
      debugPrint('PHOTO : $photoUrl');
    }
  }

  Future<void> loadHome() async {
    try {
      final repository =
      HomeRepository(
        ApiClient().dioBrowse,
      );

      final response = await repository.getHome();

      debugPrint('================ HOME =================');
      debugPrint('HOME SHELVES : ${response.shelves.length}');

      for (final shelf in response.shelves) {
        debugPrint(
          'HOME => "${shelf.title}" '
              'items=${shelf.items.length}',
        );
      }

      final more1 =
      await repository.load1(
        '4qmFsgKhAhIMRkVtdXNpY19ob21lGpACQ0FONnh3RkhUVmh2TURoZmF5MUtVVVJYYjBWQ1EyNDRTMHBJYkRCWU0wSm9XakpXWm1NeU5XaGpTRTV2WWpOU1ptSllWbnBoVjA1bVkwZEdibHBXT1hsYVYyUndZakkxYUdKQ1NXWlZWRVl6VkVkc1ptVnNSbkJsVlVaVlVWVlNSR0pZV25oalZtaHFXVzVHZEZWSFNqVlhWRnB2WVhodk1sUllWbnBoVjA1RllWaE9hbUl6V214amJteFJXVmRrYkZVeVZubGtiV3hxV2xNeFNGcFlVa2xpTWpGc1ZVZEdibHBSUVVKQlIyeHJRVUZHU2xKQlFVSlRWVkZCUVZGRlJDMXdla2gyVVd0RFEwRlI=',
      );

      final more2 = await repository.load2(
        '4qmFsgKhAhIMRkVtdXNpY19ob21lGpACQ0FaNnh3RkhTV0Z6ZGs5MVpHaHdWVVJYYjBWQ1EyNDRTMHBJYkRCWU0wSm9XakpXWm1NeU5XaGpTRTV2WWpOU1ptSllWbnBoVjA1bVkwZEdibHBXT1hsYVYyUndZakkxYUdKQ1NXWlJWRlY0WVVSc2FsVkVTbHBrVlZadFVWVlNSR0pZV25oalZtaHFXVzA0ZVU5R1dYaFZhbVJEWVhodk1sUllWbnBoVjA1RllWaE9hbUl6V214amJteFJXVmRrYkZVeVZubGtiV3hxV2xNeFNGcFlVa2xpTWpGc1ZVZEdibHBSUVVKQlIyeHJRVUZHU2xKQlFVSlRWVkZCUVZGRlJDMXdla2gyVVd0RFEwRmo=',
      );

      debugPrint('============= CONTINUATION 1 =============');
      debugPrint('CONTINUATION SHELVES 1 : ${more1.shelves.length}');
      debugPrint('============= CONTINUATION 2 =============');
      debugPrint('CONTINUATION SHELVES 2 : ${more2.shelves.length}');

      for (final shelf in more1.shelves) {
        debugPrint(
          'CONTINUATION 1 => "${shelf.title}" '
              'items=${shelf.items.length}',
        );
      }
      for (final shelf in more2.shelves) {
        debugPrint(
          'CONTINUATION 2 => "${shelf.title}" '
              'items=${shelf.items.length}',
        );
      }

      final allShelves = [
        ...response.shelves,
        ...more1.shelves,
        ...more2.shelves,
      ];

      debugPrint(
        'HOME COUNT = ${response.shelves.length}',
      );

      debugPrint(
        'MORE COUNT = ${more1.shelves.length}',
      );

      debugPrint(
        'ALL COUNT = ${allShelves.length}',
      );

      for (int i = 0; i < allShelves.length; i++) {
        debugPrint(
          '[$i] ${allShelves[i].title} (${allShelves[i].items.length})',
        );
      }

      if (!mounted) return;

      debugPrint(
        'TOTAL SHELVES : ${allShelves.length}',
      );

      for (final shelf in allShelves) {
        debugPrint(
          'SHELF => ${shelf.title} (${shelf.items.length} items)',
        );

        for (final album in shelf.items.take(5)) {
          debugPrint(
            '   • ${album.title} | ${album.subtitle}',
          );
        }
      }

      setState(() {
        shelves = allShelves.where((shelf) {
          final title = getShelfTitle(shelf.title).toLowerCase();

          // Skip jika judul mengandung "Rilis Baru"
          // if (title.contains('rilis baru')) {
          //   return false;
          // }

          // Skip jika playlist kosong
          if (shelf.items.isEmpty) {
            return false;
          }

          return true;
        }).toList();

        isLoading = false;
      });
    } catch (e, s) {
      debugPrint(
        "ERROR : $e",
      );
      debugPrint(
        s.toString(),
      );

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }


}