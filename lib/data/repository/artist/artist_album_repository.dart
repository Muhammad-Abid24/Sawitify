part of 'artist_repository.dart';

// ======================================================
// ALBUM
// ======================================================

extension ArtistAlbumRepository on ArtistRepository {
  List<ArtistAlbum> _parseAlbums(Map<String, dynamic> json) {
    return _parseAlbumSection(json, "album");
  }

  // ======================================================
  // SINGLES
  // ======================================================

  List<ArtistAlbum> _parseSingles(Map<String, dynamic> json) {
    return _parseAlbumSection(json, "single & ep");
  }

  // ======================================================
  // FEATURED ON
  // ======================================================

  List<FeaturedOn> _parseFeaturedOn(Map<String, dynamic> json) {
    return _parseAlbumSectionFeaturedOn(json, const [
      "featured on",
      "termasuk di",
    ]);
  }

  // ======================================================
  // PLAYLIST BY ARTIST
  // ======================================================

  List<FeaturedOn> _parsePlaylistArtist(Map<String, dynamic> json) {
    return _parseAlbumSectionFeaturedOn(json, const [
      "muncul di",
      "playlist dari",
      "playlist by",
    ]);
  }

  // ======================================================
  // SECTION
  // ======================================================

  List<FeaturedOn> _parseAlbumSectionFeaturedOn(
    Map<String, dynamic> json,
    List<String> sectionTitles,
  ) {
    final List<FeaturedOn> featureOn = [];

    final sections = _sectionList(json);

    for (final section in sections) {
      final shelf =
          section["musicCarouselShelfRenderer"] as Map<String, dynamic>?;

      if (shelf == null) {
        continue;
      }

      final title = _carouselTitle(shelf).toLowerCase().trim();

      final matched = sectionTitles.any((e) => title.contains(e.toLowerCase()));

      if (!matched) {
        continue;
      }

      final List contents =
          shelf["contents"] as List? ?? shelf["items"] as List? ?? [];

      for (final item in contents) {
        final renderer =
            item["musicTwoRowItemRenderer"] as Map<String, dynamic>?;

        if (renderer == null) {
          continue;
        }

        featureOn.add(_parseFeaturedOnModel(renderer));
      }

      break;
    }

    return featureOn;
  }

  // ======================================================
  // SECTION
  // ======================================================

  List<ArtistAlbum> _parseAlbumSection(
    Map<String, dynamic> json,
    String sectionTitle,
  ) {
    final List<ArtistAlbum> albums = [];

    final sections = _sectionList(json);

    for (final section in sections) {
      final shelf =
          section["musicCarouselShelfRenderer"] as Map<String, dynamic>?;

      if (shelf == null) {
        continue;
      }

      final title = _carouselTitle(shelf).toLowerCase();

      if (title != sectionTitle) {
        continue;
      }

      final List contents =
          shelf["contents"] as List? ?? shelf["items"] as List? ?? [];

      for (final item in contents) {
        final renderer =
            item["musicTwoRowItemRenderer"] as Map<String, dynamic>?;

        if (renderer == null) {
          continue;
        }

        albums.add(_parseAlbum(renderer));
      }

      break;
    }

    return albums;
  }

  // ======================================================
  // PARSE ALBUM
  // ======================================================

  ArtistAlbum _parseAlbum(Map<String, dynamic> renderer) {
    final List subtitleRuns = renderer["subtitle"]?["runs"] as List? ?? [];

    return ArtistAlbum(
      browseId: _browseId(renderer),
      title: _title(renderer),
      year: _year(subtitleRuns),
      thumbnail: _thumbnail(renderer["thumbnailRenderer"]),
    );
  }

  FeaturedOn _parseFeaturedOnModel(Map<String, dynamic> renderer) {
    final List subtitleRuns = renderer["subtitle"]?["runs"] as List? ?? [];

    final subtitle = subtitleRuns.isNotEmpty
        ? (subtitleRuns.first["text"] ?? "").toString()
        : "";

    return FeaturedOn(
      browseId: _browseId(renderer),
      title: _title(renderer),
      thumbnail: _thumbnail(renderer["thumbnailRenderer"]),
      subtitle: subtitle,
    );
  }
}
