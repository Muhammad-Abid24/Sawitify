import 'dart:async';
import 'dart:io';

import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawitify/core/theme/app_theme.dart';

import '../../core/network/api_client.dart';
import '../../core/network/response/home_response.dart';
import '../../core/storage/session_manager.dart';
import '../../core/utils/audio_output.dart';
import '../../data/model/concert_model.dart';
import '../../data/model/track_model.dart';
import '../../data/repository/concert_repository.dart';
import '../../data/repository/playlist_repository.dart';
import '../../data/repository/home_repository.dart';
import '../../data/service/music_service/music_service.dart';
import '../widgets/album_card.dart';
import 'all_playlist_page.dart';
import 'playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  List<ConcertModel> concerts1 = [];
  List<ConcertModel> concerts2 = [];
  List<ConcertModel> concerts3 = [];

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
    loadConcert1();

    _scrollController.addListener(_updateScrollbar);
  }

  final CardStackSwiperController _concertController =
      CardStackSwiperController();

  @override
  void dispose() {
    _scrollController.dispose();
    _concertController.dispose();

    super.dispose();
  }

  bool _showScrollbar = false;

  double _scrollProgress = 0;

  Timer? _scrollTimer;

  final ScrollController _scrollController = ScrollController();

  void _updateScrollbar() {
    if (!_scrollController.hasClients) {
      return;
    }

    final max = _scrollController.position.maxScrollExtent;

    if (max <= 0) {
      return;
    }

    final offset = _scrollController.offset;

    _scrollProgress = (offset / max).clamp(0.0, 1.0);

    if (!_showScrollbar) {
      setState(() {
        _showScrollbar = true;
      });
    } else {
      setState(() {});
    }

    _scrollTimer?.cancel();

    _scrollTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showScrollbar = false;
      });
    });
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

                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
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
              Center(child: Text(errorMessage!)),
            ],
          ),
        ),
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
          Container(color: Colors.black),

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
            padding: const EdgeInsets.only(top: 110),

            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await loadHome();
                    await loadConcert1();
                  },

                  child: CustomScrollView(
                    controller: _scrollController,

                    physics: const AlwaysScrollableScrollPhysics(),

                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: _buildCategories(),
                        ),
                      ),

                      _buildContent(),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),

                Positioned(
                  right: 0,

                  top: 20,

                  bottom: 160,

                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showScrollbar ? 1 : 0,

                      duration: const Duration(milliseconds: 250),

                      child: Align(
                        alignment: Alignment(1, -1 + (_scrollProgress * 2)),

                        child: Container(
                          width: 5,

                          height: 55,

                          decoration: BoxDecoration(
                            color: AppColors.primary,

                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset(
          "assets/logo/ic_logo_horizontal.png",
          width: 150,
          height: 50,
        ),
        const Spacer(),

        IconButton(
          onPressed: () async {
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
          icon: const Icon(Icons.speaker_group),
        ),
      ],
    );
  }

  int _selectedCategory = 0;
  Widget _buildCategories() {
    final categories = ["All", "Music", "Events"];

    return SizedBox(
      height: 38,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: categories.length,

        separatorBuilder: (_, __) => const SizedBox(width: 10),

        itemBuilder: (_, index) {
          final isSelected = index == _selectedCategory;

          return Material(
            color: Colors.transparent,

            child: InkWell(
              borderRadius: BorderRadius.circular(30),

              onTap: () {
                if (_selectedCategory == index) {
                  return;
                }

                setState(() {
                  _selectedCategory = index;
                });
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),

                padding: const EdgeInsets.symmetric(horizontal: 18),

                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background1,

                  borderRadius: BorderRadius.circular(30),
                ),

                alignment: Alignment.center,

                child: Text(
                  categories[index],

                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    // ================= ALL =================

    if (_selectedCategory == 0) {
      return SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (concerts1.isNotEmpty) _buildConcertSwiper(),
            const SizedBox(height: 25),

            ...shelves.map((shelf) => _buildShelf(shelf)),
          ],
        ),
      );
    }

    // ================= MUSIC =================

    if (_selectedCategory == 1) {
      return SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: shelves.map((shelf) => _buildShelf(shelf)).toList(),
        ),
      );
    }

    // ================= EVENTS =================

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 5,

                  height: 20,

                  decoration: BoxDecoration(
                    color: AppColors.primary,

                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(width: 8),

                const Text(
                  'Konser di Indonesia',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            SizedBox(
              height: 250,

              child: ListView.separated(
                scrollDirection: Axis.horizontal,

                itemCount: concerts1.length,

                separatorBuilder: (_, __) => const SizedBox(width: 13),

                itemBuilder: (_, index) {
                  return SizedBox(
                    width: 160,

                    child: _buildConcertCard1(concerts1[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConcertSwiper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const SizedBox(height: 8),

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
                'Upcoming Concert',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Center(
          child: SizedBox(
            width: 200,

            height: 200,

            child: CardStackSwiper(
              controller: _concertController,

              cardsCount: concerts1.length,

              initialIndex: 0,

              isLoop: true,

              onSwipe: (previousIndex, currentIndex, direction) {
                return true;
              },

              onEnd: () {
                debugPrint('Reached end');
              },

              cardBuilder:
                  (context, index, horizontalPercentage, verticalPercentage) {
                    return _buildStackConcertCard(concerts1[index]);
                  },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackConcertCard(ConcertModel concert) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,

        borderRadius: BorderRadius.circular(8),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .15),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          // =====================
          // IMAGE
          // =====================
          Stack(
            children: [
              SizedBox(
                height: 110,

                width: double.infinity,

                child: Image.network(
                  concert.image ?? '',

                  fit: BoxFit.cover,

                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: AppColors.background1,

                      alignment: Alignment.center,

                      child: const Icon(
                        Icons.music_note,

                        size: 35,

                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 10,

                right: 10,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,

                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.background1.withAlpha(70),

                    borderRadius: BorderRadius.circular(999),
                  ),

                  child: Text(
                    concert.startDate ?? '',

                    style: const TextStyle(
                      fontSize: 10,

                      fontWeight: FontWeight.w700,

                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // =====================
          // CONTENT
          // =====================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    concert.title,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,

                        size: 12,

                        color: Colors.white,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          concert.address.last,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 11,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    concert.when ?? '',

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcertCard1(ConcertModel concert) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),

      decoration: BoxDecoration(
        color: AppColors.background2,

        borderRadius: BorderRadius.circular(12),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          // =====================
          // IMAGE
          // =====================
          Stack(
            children: [
              SizedBox(
                height: 120,

                width: double.infinity,

                child: Image.network(
                  concert.image ?? '',

                  fit: BoxFit.cover,

                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: AppColors.background1,

                      alignment: Alignment.center,

                      child: const Icon(
                        Icons.music_note,

                        color: Colors.white,

                        size: 50,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                left: 0,

                right: 0,

                bottom: 0,

                height: 50,

                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,

                      colors: [Colors.transparent, AppColors.background2],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,

                right: 10,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,

                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(999),
                  ),

                  child: Text(
                    concert.startDate ?? '',

                    style: const TextStyle(
                      fontSize: 10,

                      color: Colors.black,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // =====================
          // CONTENT
          // =====================
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),

            child: Column(
              children: [
                Text(
                  concert.title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 15,

                    fontWeight: FontWeight.w600,

                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  concert.when ?? '',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  textAlign: TextAlign.center,

                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),

                const SizedBox(height: 4),

                Text(
                  concert.address.last,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  textAlign: TextAlign.center,

                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelf(Shelf shelf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 5,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(200),
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
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: shelf.items.length,
            itemBuilder: (_, index) {
              final item = shelf.items[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 135,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      debugPrint('CLICK PLAYLIST: ${item.title}');

                      debugPrint('BROWSE ID: ${item.browseId}');

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
                            builder: (_) => PlaylistPage(
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
                        debugPrint('SINGLE/ALBUM => ${item.title}');

                        try {
                          final repository = PlaylistRepository(
                            ApiClient().dioBrowse,
                          );

                          final response = await repository.getPlaylistDetail(
                            browseId,
                          );

                          if (response.tracks.isEmpty) {
                            return;
                          }

                          final tracks = List<TrackModel>.from(response.tracks);

                          final artist = item.subtitle.contains('•')
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

                          await MusicService.instance.setPlaylist(
                            playlist: tracks,
                            startIndex: 0,
                          );

                          await MusicService.instance.playTrack(0);
                        } catch (e) {
                          debugPrint('PLAY ALBUM ERROR: $e');
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

  Future<void> loadConcert1() async {
    try {
      debugPrint('============= LOAD FIREBASE CONCERT =============');

      final repository = ConcertRepository();

      final result = await repository.getConcerts();

      debugPrint('TOTAL CONCERT : ${result.length}');

      for (int i = 0; i < result.length; i++) {
        final item = result[i];

        debugPrint('========== CONCERT [$i] ==========');

        debugPrint('TITLE : ${item.title}');

        debugPrint('START DATE : ${item.startDate}');

        debugPrint('EVENT DATE : ${item.eventDate}');

        debugPrint('EVENT YEAR : ${item.eventYear}');

        debugPrint('WHEN : ${item.when}');

        debugPrint('ADDRESS : ${item.address.join(', ')}');

        debugPrint('DESCRIPTION : ${item.description}');

        debugPrint('LINK : ${item.link}');

        debugPrint('MAP IMAGE : ${item.mapImage}');

        debugPrint('MAP LINK : ${item.mapLink}');

        debugPrint('THUMBNAIL : ${item.thumnail}');

        debugPrint('IMAGE : ${item.image}');

        debugPrint('TICKETS : ${item.tickets.length}');

        for (int j = 0; j < item.tickets.length; j++) {
          final ticket = item.tickets[j];

          debugPrint('----- TICKET [$j] -----');

          debugPrint('SOURCE : ${ticket.source}');

          debugPrint('SOURCE ICON : ${ticket.sourceIcon}');

          debugPrint('LINK : ${ticket.link}');

          debugPrint('TYPE : ${ticket.linkType}');
        }

        debugPrint('===============================');
      }

      if (!mounted) {
        return;
      }

      result.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      debugPrint('TOTAL CONCERT : ${result.length}');
      setState(() {
        concerts1 = result;
      });
    } catch (e, s) {
      debugPrint('CONCERT ERROR : $e');

      debugPrint(s.toString());
    }
  }

  Future<void> loadHome() async {
    try {
      final repository = HomeRepository(ApiClient().dioBrowse);

      final response = await repository.getHome();

      debugPrint('================ HOME =================');
      debugPrint('HOME SHELVES : ${response.shelves.length}');

      for (final shelf in response.shelves) {
        debugPrint(
          'HOME => "${shelf.title}" '
          'items=${shelf.items.length}',
        );
      }

      final more1 = await repository.load1(
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

      debugPrint('HOME COUNT = ${response.shelves.length}');

      debugPrint('MORE COUNT = ${more1.shelves.length}');

      debugPrint('ALL COUNT = ${allShelves.length}');

      for (int i = 0; i < allShelves.length; i++) {
        debugPrint(
          '[$i] ${allShelves[i].title} (${allShelves[i].items.length})',
        );
      }

      if (!mounted) return;

      debugPrint('TOTAL SHELVES : ${allShelves.length}');

      for (final shelf in allShelves) {
        debugPrint('SHELF => ${shelf.title} (${shelf.items.length} items)');

        for (final album in shelf.items.take(5)) {
          debugPrint('   • ${album.title} | ${album.subtitle}');
        }
      }

      setState(() {
        shelves = allShelves.where((shelf) {
          // Skip jika playlist kosong
          if (shelf.items.isEmpty) {
            return false;
          }

          return true;
        }).toList();

        isLoading = false;
      });
    } catch (e, s) {
      debugPrint("ERROR : $e");
      debugPrint(s.toString());

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
