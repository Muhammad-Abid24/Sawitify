import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sawitify/core/utils/audio_output.dart';
import 'package:sawitify/data/model/track_model.dart';
import 'package:sawitify/data/service/music_service/music_service.dart';
import 'package:sawitify/presentation/pages/artist_page.dart';
import 'package:sawitify/presentation/pages/playlist_page.dart';
import 'package:sawitify/presentation/widgets/my_form.dart';
import '../../core/network/api_client.dart';
import '../../data/model/search_model.dart';
import '../../data/repository/search_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();
  final _repository = SearchRepository(ApiClient());
  List<SearchItem> _items = [];
  List<String> _suggestions = [];
  Timer? _debounce;

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
                capitalize: TextCapitalization.none,
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
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, index) {
                  final item = _items[index];

                  return ListTile(
                    onTap: () => _onItemTap(item),

                    leading: SizedBox(
                      width: 45,
                      height: 45,
                      child: _buildThumbnail(item),
                    ),

                    title: Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),

                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                },
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
    final keyword = searchController.text.trim();

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (keyword.isEmpty) {
        if (!mounted) return;

        setState(() {
          _items.clear();
          _suggestions.clear();
        });

        return;
      }

      await _search(keyword);
    });
  }

  Future<void> _search(String keyword) async {
    if (!mounted) return;

    setState(() {});

    try {
      final result = await _repository.search(keyword);

      if (!mounted) return;

      setState(() {
        _items = result.items.where((item) {
          switch (item.type) {
            case SearchItemType.song:
            case SearchItemType.album:
            case SearchItemType.playlist:
              return true;

            // jika Single diparsing sebagai Album
            case SearchItemType.artist:
            case SearchItemType.suggestion:
            case SearchItemType.unknown:
              return false;
          }
        }).toList();

        _suggestions = result.suggestions;
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildThumbnail(SearchItem item) {
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
            item.type == SearchItemType.artist
                ? Icons.person
                : Icons.music_note,
            color: Colors.white,
          ),
        );
      },
    );

    if (item.type == SearchItemType.artist) {
      return ClipOval(child: image);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(7), child: image);
  }

  Future<void> _playSong(SearchItem item) async {
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

  Future<void> _onItemTap(SearchItem item) async {
    switch (item.type) {
      case SearchItemType.artist:
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

      case SearchItemType.album:
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

      case SearchItemType.playlist:
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

      case SearchItemType.song:
        await _playSong(item);
        break;

      default:
        break;
    }
  }
}
