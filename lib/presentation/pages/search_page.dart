import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sawitify/core/theme/app_theme.dart';
import 'package:sawitify/core/utils/audio_output.dart';
import 'package:sawitify/data/model/track_model.dart';
import 'package:sawitify/data/service/music_service/music_service.dart';
import 'package:sawitify/presentation/pages/album_page.dart';
import 'package:sawitify/presentation/pages/artist_page.dart' hide AlbumPage;
import 'package:sawitify/presentation/pages/playlist_page.dart';
import 'package:sawitify/presentation/widgets/my_form.dart';
import '../../core/network/api_client.dart';
import '../../data/model/search_suggestion_model.dart';
import '../../data/repository/search_suggestion_repository.dart';

import '../../data/model/search_model.dart' as search;
import '../../data/repository/search_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();

  // ==========================
  // Repository
  // ==========================
  final _suggestionRepository = SearchSuggestionRepository(ApiClient());
  final _searchRepository = SearchRepository(ApiClient());

  // ==========================
  // Search Suggestion
  // ==========================
  List<SearchSuggestionItem> _suggestionItems = [];
  List<String> _suggestions = [];

  // ==========================
  // Search Result
  // ==========================
  List<search.SearchItem> _searchItems = [];

  // List yang benar-benar ditampilkan oleh ListView
  List<search.SearchItem> _filteredItems = [];

  // false = autocomplete
  // true  = hasil search
  bool _showSearchResult = false;

  Timer? _debounce;

  bool _ignoreSearchListener = false;

  // digunakan untuk menghindari race condition
  int _searchRequestId = 0;

  int _selectedResult = 0;

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();

    super.dispose();
  }

  /// ==========================
  /// Apply Filter
  /// ==========================
  void _applyFilter() {
    switch (_selectedResult) {
      case 1:
        _filteredItems = _searchItems
            .where((e) => e.type == search.SearchItemType.artist)
            .toList();
        break;

      case 2:
        _filteredItems = _searchItems
            .where((e) => e.type == search.SearchItemType.song)
            .toList();
        break;

      case 3:
        _filteredItems = _searchItems
            .where((e) => e.type == search.SearchItemType.album)
            .toList();
        break;

      default:
        _filteredItems = List.of(_searchItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildHeader(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: MyForm(
                controller: searchController,
                hintText: 'Artist, Songs, Albums and More..',
                prefixIcon: Icons.search,
              ),
            ),

            /*Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(vertical: 170),
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 80, color: AppColors.primary),
                      SizedBox(height: 1),
                      Text(
                        'No Recent Searches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        textAlign: TextAlign.center,
                        'You recent searches\nwill appear here',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),*/
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _showSearchResult
                  ? Padding(
                      key: const ValueKey("result"),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: _buildResult(),
                    )
                  : const SizedBox(key: ValueKey("empty")),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,

                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, .04),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },

                child: ListView.builder(
                  key: ValueKey("${_showSearchResult}_${_selectedResult}"),

                  itemCount: _showSearchResult
                      ? _filteredItems.length
                      : _suggestions.length + _suggestionItems.length,

                  itemBuilder: (_, index) {
                    // ======================================================
                    // SEARCH RESULT
                    // ======================================================
                    if (_showSearchResult) {
                      if (index >= _filteredItems.length) {
                        return const SizedBox.shrink();
                      }

                      final item = _filteredItems[index];

                      return Column(
                        children: [
                          ListTile(
                            onTap: () => _onSearchItemTap(item),

                            leading: SizedBox(
                              width: 45,
                              height: 45,
                              child: _buildSearchThumbnail(item),
                            ),

                            title: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),

                            subtitle: Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 70, right: 12),
                            child: Divider(
                              height: 1,
                              thickness: .1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    }

                    // ======================================================
                    // SEARCH SUGGESTION
                    // ======================================================
                    if (index < _suggestions.length) {
                      final suggestion = _suggestions[index];

                      return ListTile(
                        leading: const Icon(Icons.search, color: Colors.white),

                        title: Text(
                          suggestion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.north_west,
                            color: Colors.white,
                          ),

                          onPressed: () async {
                            await _onSuggestionSelected(suggestion);
                          },
                        ),

                        onTap: () async {
                          await _onSuggestionSelected(suggestion);
                        },
                      );
                    }

                    // ======================================================
                    // SEARCH ITEM
                    // ======================================================
                    final suggestionIndex = index - _suggestions.length;

                    if (suggestionIndex >= _suggestionItems.length) {
                      return const SizedBox.shrink();
                    }

                    final item = _suggestionItems[suggestionIndex];

                    return Column(
                      children: [
                        ListTile(
                          onTap: () => _onItemTap(item),

                          leading: SizedBox(
                            width: 45,
                            height: 45,
                            child: _buildThumbnail(item),
                          ),

                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),

                          subtitle: Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(left: 70, right: 12),
                          child: Divider(
                            height: 1,
                            thickness: .1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Search',
          style: TextStyle(
            fontSize: 27,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
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
          icon: const Icon(Icons.cast),
        ),
      ],
    );
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

  void _onSearchChanged() {
    if (_ignoreSearchListener) {
      _debounce?.cancel();
      return;
    }

    final keyword = searchController.text.trim();

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      if (keyword.isEmpty) {
        setState(() {
          _showSearchResult = false;

          _selectedResult = 0;

          _suggestions.clear();
          _suggestionItems.clear();

          _searchItems.clear();
          _filteredItems.clear();
        });

        return;
      }

      await _searchSuggestion(keyword);
    });
  }

  Future<void> _searchSuggestion(String keyword) async {
    if (!mounted) return;

    final requestId = ++_searchRequestId;

    try {
      final result = await _suggestionRepository.searchSuggestion(keyword);

      if (!mounted) return;

      if (requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _showSearchResult = false;

        _suggestions = result.suggestions;

        _suggestionItems = result.items.where((item) {
          switch (item.type) {
            case SearchSuggestionItemType.artist:
            case SearchSuggestionItemType.song:
            case SearchSuggestionItemType.album:
            case SearchSuggestionItemType.playlist:
              return true;

            case SearchSuggestionItemType.suggestion:
            case SearchSuggestionItemType.unknown:
              return false;
          }
        }).toList();

        _searchItems.clear();
        _filteredItems.clear();
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _search(String keyword) async {
    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final requestId = ++_searchRequestId;

    try {
      final results = await Future.wait([
        _searchRepository.searchArtists(keyword),
        _searchRepository.searchSongs(keyword),
        _searchRepository.searchAlbums(keyword),
      ]);

      if (!mounted) return;

      if (requestId != _searchRequestId) {
        return;
      }

      _searchItems = [...results[0], ...results[1], ...results[2]];

      _selectedResult = 0;

      _applyFilter();

      setState(() {
        _showSearchResult = true;

        _suggestions.clear();
        _suggestionItems.clear();
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }
  }

  Widget _buildThumbnail(SearchSuggestionItem item) {
    final image = Image.network(
      item.thumbnail,
      width: 45,
      height: 45,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey.shade900,
          alignment: Alignment.center,
          child: Icon(
            item.type == SearchSuggestionItemType.artist
                ? Icons.person
                : Icons.music_note,
            color: Colors.white,
          ),
        );
      },
    );

    if (item.type == SearchSuggestionItemType.artist) {
      return ClipOval(child: image);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(7), child: image);
  }

  Widget _buildSearchThumbnail(search.SearchItem item) {
    final image = Image.network(
      item.thumbnail,
      width: 45,
      height: 45,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey.shade900,
          alignment: Alignment.center,
          child: Icon(
            item.type == search.SearchItemType.artist
                ? Icons.person
                : Icons.music_note,
            color: Colors.white,
          ),
        );
      },
    );

    if (item.type == search.SearchItemType.artist) {
      return ClipOval(child: image);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(7), child: image);
  }

  Future<void> _playSong(SearchSuggestionItem item) async {
    try {
      final track = TrackModel(
        videoId: item.id,
        title: item.title,
        artist: item.subtitle
            .replaceFirst("Lagu • ", "")
            .split("•")
            .first
            .trim(),
        thumbnail: item.thumbnail,
        duration: "",
      );

      await MusicService.instance.setPlaylist(
        playlist: [track],
        startIndex: 0,
        playlistName: "Search",
      );

      await MusicService.instance.playTrack(0);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _playSearchSong(search.SearchItem item) async {
    try {
      final track = TrackModel(
        videoId: item.id,
        title: item.title,
        artist: item.subtitle
            .replaceFirst("Lagu • ", "")
            .split("•")
            .first
            .trim(),
        thumbnail: item.thumbnail,
        duration: "",
      );

      await MusicService.instance.setPlaylist(
        playlist: [track],
        startIndex: 0,
        playlistName: "Search",
      );

      await MusicService.instance.playTrack(0);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _onItemTap(SearchSuggestionItem item) async {
    switch (item.type) {
      case SearchSuggestionItemType.artist:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case SearchSuggestionItemType.album:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case SearchSuggestionItemType.playlist:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case SearchSuggestionItemType.song:
        await _playSong(item);
        break;

      case SearchSuggestionItemType.suggestion:
      case SearchSuggestionItemType.unknown:
        break;
    }
  }

  Future<void> _onSearchItemTap(search.SearchItem item) async {
    switch (item.type) {
      case search.SearchItemType.artist:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case search.SearchItemType.album:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case search.SearchItemType.playlist:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistPage(
              browseId: item.id,
              title: item.title,
              subTitle: item.subtitle,
              thumbnail: item.thumbnail,
            ),
          ),
        );
        break;

      case search.SearchItemType.song:
        await _playSearchSong(item);
        break;

      case search.SearchItemType.unknown:
        break;
    }
  }

  Future<void> _onSuggestionSelected(String suggestion) async {
    FocusScope.of(context).unfocus();

    _ignoreSearchListener = true;

    searchController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );

    try {
      await _search(suggestion);
    } finally {
      _ignoreSearchListener = false;
    }
  }

  Widget _buildResult() {
    final categories = ["All", "Artist", "Song", "Album"];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final isSelected = index == _selectedResult;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                if (_selectedResult == index) return;

                setState(() {
                  _selectedResult = index;
                  _applyFilter();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background1,
                  borderRadius: BorderRadius.circular(30),
                ),
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
}
