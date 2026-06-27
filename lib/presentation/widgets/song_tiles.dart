import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sawitify/data/model/track_model.dart';
import 'package:sawitify/data/service/music_service/music_service.dart';

class SongTiles extends StatelessWidget {
  final TrackModel track;

  final List<TrackModel> playlist;

  final int index;

  final bool isTablet;

  final String playlistName;

  const SongTiles({
    super.key,
    required this.track,
    required this.playlist,
    required this.index,
    required this.isTablet,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () async {
          try {
            await MusicService.instance.setPlaylist(
              playlist: playlist,
              startIndex: index,
              playlistName: playlistName,
            );

            await MusicService.instance.playTrack(index);
          } catch (e) {
            debugPrint(e.toString());
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
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: isTablet ? 18 : 16),
          ),

          subtitle: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54),
          ),

          trailing: const Icon(Icons.more_horiz, color: Colors.white54),
        ),
      ),
    );
  }
}
