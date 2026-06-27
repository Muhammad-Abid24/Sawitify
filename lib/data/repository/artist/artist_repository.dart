import 'package:flutter/rendering.dart';
import 'package:sawitify/core/network/api_client.dart';
import 'package:sawitify/core/network/service_config.dart';
import 'package:sawitify/data/model/artist_model.dart';
import 'package:sawitify/data/model/track_model.dart';

part 'artist_header_repository.dart';

part 'artist_track_repository.dart';

part 'artist_album_repository.dart';
part 'artist_video_repository.dart';
part 'artist_related_repository.dart';
part 'artist_helper_repository.dart';

class ArtistRepository {
  ArtistRepository(this.api);

  final ApiClient api;

  Future<ArtistResponse> getArtist(String browseId) async {
    final Map<String, dynamic> json =
        await api.apiBrowse.browse(
              {
                "context": {
                  "client": {
                    "clientName": "WEB_REMIX",
                    "clientVersion": "1.20260623.13.00",
                    "hl": "id",
                    "gl": "ID",
                  },
                  "user": {"enableSafetyMode": false},
                },
                "browseId": browseId,
              },
              "json",
              ServiceConfig.apiKey!,
            )
            as Map<String, dynamic>;

    final artist = _parseHeader(json, browseId);

    return ArtistResponse(
      artist: artist,

      topSongs: _parseTopSongs(json),

      albums: _parseAlbums(json),

      singles: _parseSingles(json),

      videos: _parseVideos(json),

      featuredOn: _parseFeaturedOn(json),
      playlistArtist: _parsePlaylistArtist(json),

      relatedArtists: _parseRelatedArtists(json),
    );
  }
}
