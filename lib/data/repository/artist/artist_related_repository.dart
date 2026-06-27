part of 'artist_repository.dart';

// ======================================================
// RELATED ARTISTS
// ======================================================

extension ArtistRelatedRepository on ArtistRepository {
  List<RelatedArtist> _parseRelatedArtists(Map<String, dynamic> json) {
    final List<RelatedArtist> artists = [];

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

      if (title != "artis terkait" && title != "related artists") {
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

          artists.add(_parseRelatedArtist(renderer));
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

          artists.add(_parseResponsiveRelatedArtist(renderer));
        }
      }

      break;
    }

    return artists;
  }

  // ======================================================
  // TWO ROW ARTIST
  // ======================================================

  RelatedArtist _parseRelatedArtist(Map<String, dynamic> renderer) {
    final subtitleRuns = renderer["subtitle"]?["runs"] as List? ?? [];

    return RelatedArtist(
      browseId: _browseId(renderer),
      name: _title(renderer),
      thumbnail: _thumbnail(renderer["thumbnailRenderer"]),
      subscribers: _joinRuns(subtitleRuns),
    );
  }

  // ======================================================
  // RESPONSIVE ARTIST
  // ======================================================

  RelatedArtist _parseResponsiveRelatedArtist(Map<String, dynamic> renderer) {
    final List flexColumns = renderer["flexColumns"] as List? ?? [];

    String name = "";

    List subtitleRuns = [];

    if (flexColumns.isNotEmpty) {
      name = _joinRuns(
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

    return RelatedArtist(
      browseId: _browseId(renderer),
      name: name,
      thumbnail: _thumbnail(renderer["thumbnail"]),
      subscribers: _joinRuns(subtitleRuns),
    );
  }
}
