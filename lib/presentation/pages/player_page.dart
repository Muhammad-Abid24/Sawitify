import 'package:flutter/cupertino.dart';

import '../../data/service/music_service/music_service.dart';
import '../widgets/player_content.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

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

        final hdThumbnail = track.thumbnail.replaceAll(
          RegExp(r'=w\d+-h\d+.*'),
          '=w1200-h1200',
        );

        return DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.15,
          maxChildSize: 1,
          snap: true,
          expand: false,

          builder: (context, controller) {
            return PlayerContent(
              imageUrl: hdThumbnail.trim().isNotEmpty
                  ? hdThumbnail
                  : 'assets/logo/ic_sawity.png',

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
