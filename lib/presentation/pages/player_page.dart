import 'package:flutter/cupertino.dart';

import '../../data/service/music_service/music_service.dart';
import '../widgets/player_content.dart';

class PlayerPage extends StatefulWidget {
  final String? videoId;

  const PlayerPage({super.key, this.videoId});

  @override
  State<PlayerPage> createState() => _PlayerPage();
}

class _PlayerPage extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicService.instance,

      builder: (_, __) {
        final music = MusicService.instance;

        final track = music.currentTrack;

        final duration = music.trackDuration;

        final playlistName = music.playlistName;

        final durationText =
            "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";

        if (track == null) {
          return const SizedBox();
        }

        // final hdThumbnail = track.thumbnail.replaceAll(
        //   RegExp(r'=w\d+-h\d+.*'),
        //   '=w1200-h1200',
        // );

        final imageUrl = track.thumbnail.trim().isNotEmpty
            ? track.thumbnail.replaceAll(
                RegExp(r'=w\d+-h\d+.*'),
                '=w1200-h1200',
              )
            : 'https://i.ytimg.com/vi/${widget.videoId ?? track.videoId}/maxresdefault.jpg';

        return DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.15,
          maxChildSize: 1,
          snap: true,
          expand: false,

          builder: (context, controller) {
            return PlayerContent(
              imageUrl: imageUrl,

              controller: controller,

              title: track.title,

              artist: track.artist,

              duration: durationText,

              videoId: track.videoId,

              playlistName: playlistName,
            );
          },
        );
      },
    );
  }
}
