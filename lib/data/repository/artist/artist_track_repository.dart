part of 'artist_repository.dart';

// ======================================================
// TOP SONGS
// ======================================================

extension ArtistTrackRepository on ArtistRepository {
  List<TrackModel> _parseTopSongs(Map<String, dynamic> json) {
    final List<TrackModel> tracks = [];

    final sections = _sectionList(json);

    for (final section in sections) {
      final shelf = section["musicShelfRenderer"] as Map<String, dynamic>?;

      if (shelf == null) {
        continue;
      }

      final title = _shelfTitle(shelf).toLowerCase();

      if (title != "lagu teratas") {
        continue;
      }

      final List contents = shelf["contents"] as List? ?? [];

      for (final item in contents) {
        final renderer =
            item["musicResponsiveListItemRenderer"] as Map<String, dynamic>?;

        if (renderer == null) {
          continue;
        }

        tracks.add(_parseTrack(renderer));
      }

      break;
    }

    return tracks;
  }

  // ======================================================
  // TRACK
  // ======================================================

  TrackModel _parseTrack(Map<String, dynamic> renderer) {
    final List flexColumns = renderer["flexColumns"] as List? ?? [];

    //--------------------------------------------------
    // TITLE
    //--------------------------------------------------

    String title = "";

    if (flexColumns.isNotEmpty) {
      title = _joinRuns(
        flexColumns[0]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
            as List?,
      );
    }

    //--------------------------------------------------
    // SUBTITLE
    //--------------------------------------------------

    List subtitleRuns = [];

    if (flexColumns.length > 1) {
      subtitleRuns =
          flexColumns[1]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
              as List? ??
          [];
    }

    //--------------------------------------------------
    // PARSE METADATA
    //--------------------------------------------------

    final metadata = _parseTrackRuns(subtitleRuns);

    debugPrint("========== TRACK ==========");
    debugPrint("TITLE = $title");
    debugPrint("VIDEO = ${_videoId(renderer)}");
    debugPrint("NAV = ${renderer["navigationEndpoint"]}");
    debugPrint("RENDERER KEYS = ${renderer.keys}");
    debugPrint("===========================");

    //--------------------------------------------------
    // RESULT
    //--------------------------------------------------

    return TrackModel(
      videoId: _videoId(renderer),
      title: title,
      artist: metadata.artist,
      artistId: metadata.artistId,
      album: metadata.album,
      albumId: metadata.albumId,
      thumbnail: _thumbnail(renderer["thumbnail"]),
      duration: metadata.duration,
    );
  }
}
