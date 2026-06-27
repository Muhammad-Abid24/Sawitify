part of 'artist_repository.dart';

// ======================================================
// VIDEOS
// ======================================================

extension ArtistVideoRepository on ArtistRepository {
  List<ArtistVideo> _parseVideos(Map<String, dynamic> json) {
    final List<ArtistVideo> videos = [];

    final sections = _sectionList(json);

    for (final section in sections) {
      final shelf =
          section["musicCarouselShelfRenderer"] as Map<String, dynamic>? ??
          section["musicShelfRenderer"] as Map<String, dynamic>?;

      if (shelf == null) {
        continue;
      }

      final title = shelf["header"] != null
          ? _carouselTitle(shelf).toLowerCase()
          : _shelfTitle(shelf).toLowerCase();

      if (title != "video") {
        continue;
      }

      //--------------------------------------------------
      // musicCarouselShelfRenderer
      //--------------------------------------------------

      if (section["musicCarouselShelfRenderer"] != null) {
        final List contents =
            shelf["contents"] as List? ?? shelf["items"] as List? ?? [];

        for (final item in contents) {
          final renderer =
              item["musicTwoRowItemRenderer"] as Map<String, dynamic>?;

          if (renderer == null) {
            continue;
          }

          videos.add(_parseVideo(renderer));
        }
      }
      //--------------------------------------------------
      // musicShelfRenderer
      //--------------------------------------------------
      else {
        final List contents = shelf["contents"] as List? ?? [];

        for (final item in contents) {
          final renderer =
              item["musicResponsiveListItemRenderer"] as Map<String, dynamic>?;

          if (renderer == null) {
            continue;
          }

          videos.add(_parseResponsiveVideo(renderer));
        }
      }

      break;
    }

    return videos;
  }

  // ======================================================
  // TWO ROW VIDEO
  // ======================================================

  ArtistVideo _parseVideo(Map<String, dynamic> renderer) {
    final subtitleRuns = renderer["subtitle"]?["runs"] as List? ?? [];

    return ArtistVideo(
      videoId: _videoId(renderer),
      title: _title(renderer),
      thumbnail: _thumbnail(renderer["thumbnailRenderer"]),
      views: _views(subtitleRuns),
    );
  }

  // ======================================================
  // RESPONSIVE VIDEO
  // ======================================================

  ArtistVideo _parseResponsiveVideo(Map<String, dynamic> renderer) {
    final List flexColumns = renderer["flexColumns"] as List? ?? [];

    String title = "";

    List subtitleRuns = [];

    if (flexColumns.isNotEmpty) {
      title = _joinRuns(
        flexColumns[0]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
            as List?,
      );
    }

    if (flexColumns.length > 1) {
      subtitleRuns =
          flexColumns[1]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
              as List? ??
          [];
    }

    return ArtistVideo(
      videoId: _videoId(renderer),
      title: title,
      thumbnail: _thumbnail(renderer["thumbnail"]),
      views: _views(subtitleRuns),
    );
  }
}
