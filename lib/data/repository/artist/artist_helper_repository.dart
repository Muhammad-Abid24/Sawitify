part of 'artist_repository.dart';

// ======================================================
// SECTION
// ======================================================

List<Map<String, dynamic>> _sectionList(Map<String, dynamic> json) {
  final List sections =
      json["contents"]?["singleColumnBrowseResultsRenderer"]?["tabs"]?[0]?["tabRenderer"]?["content"]?["sectionListRenderer"]?["contents"]
          as List? ??
      [];

  return sections.cast<Map<String, dynamic>>();
}

// ======================================================
// TITLE
// ======================================================

String _shelfTitle(Map<String, dynamic> shelf) {
  return _joinRuns(shelf["title"]?["runs"] as List?);
}

String _carouselTitle(Map<String, dynamic> shelf) {
  return _joinRuns(
    shelf["header"]?["musicCarouselShelfBasicHeaderRenderer"]?["title"]?["runs"]
        as List?,
  );
}

String _title(Map<String, dynamic> renderer) {
  return _joinRuns(renderer["title"]?["runs"] as List?);
}

String _subtitle(Map<String, dynamic> renderer) {
  return _joinRuns(renderer["subtitle"]?["runs"] as List?);
}

// ======================================================
// RUNS
// ======================================================

String _joinRuns(List? runs) {
  if (runs == null || runs.isEmpty) {
    return "";
  }

  return runs.map((e) => e["text"]?.toString() ?? "").join();
}

// ======================================================
// THUMBNAIL
// ======================================================

String _thumbnail(dynamic renderer) {
  if (renderer == null) {
    return "";
  }

  List thumbnails = [];

  if (renderer["musicThumbnailRenderer"] != null) {
    thumbnails =
        renderer["musicThumbnailRenderer"]["thumbnail"]["thumbnails"]
            as List? ??
        [];
  } else if (renderer["thumbnail"] != null) {
    thumbnails = renderer["thumbnail"]["thumbnails"] as List? ?? [];
  }

  if (thumbnails.isEmpty) {
    return "";
  }

  return thumbnails.last["url"]?.toString() ?? "";
}

// ======================================================
// IDS
// ======================================================

String _browseId(Map<String, dynamic> renderer) {
  return renderer["navigationEndpoint"]?["browseEndpoint"]?["browseId"]
          ?.toString() ??
      "";
}

String _videoId(Map<String, dynamic> renderer) {
  debugPrint("playlistItemData = ${renderer["playlistItemData"]}");
  debugPrint("overlay = ${renderer["overlay"]}");
  // 1. playlistItemData (Artist Top Songs)
  final playlistVideoId = renderer["playlistItemData"]?["videoId"]?.toString();

  if (playlistVideoId != null && playlistVideoId.isNotEmpty) {
    return playlistVideoId;
  }

  // 2. overlay play button
  final overlayVideoId =
      renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["content"]?["musicPlayButtonRenderer"]?["playNavigationEndpoint"]?["watchEndpoint"]?["videoId"]
          ?.toString();

  if (overlayVideoId != null && overlayVideoId.isNotEmpty) {
    return overlayVideoId;
  }

  // 3. navigationEndpoint (Playlist/Search)
  final navigationVideoId =
      renderer["navigationEndpoint"]?["watchEndpoint"]?["videoId"]?.toString();

  if (navigationVideoId != null && navigationVideoId.isNotEmpty) {
    return navigationVideoId;
  }

  return "";
}

// ======================================================
// TRACK
// ======================================================

String _artist(List? runs) {
  if (runs == null || runs.isEmpty) {
    return "";
  }

  // Prioritas: item yang memiliki browseEndpoint artist.
  for (final run in runs) {
    final endpoint = run["navigationEndpoint"];

    if (endpoint != null && endpoint["browseEndpoint"] != null) {
      return run["text"]?.toString() ?? "";
    }
  }

  // Fallback: ambil teks sebelum bullet pertama.
  final buffer = StringBuffer();

  for (final run in runs) {
    final text = run["text"]?.toString() ?? "";

    if (text == "•") {
      break;
    }

    buffer.write(text);
  }

  return buffer.toString().trim();
}

String _duration(List? runs) {
  if (runs == null || runs.isEmpty) {
    return "";
  }

  final durationRegex = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');

  for (final run in runs.reversed) {
    final text = run["text"]?.toString() ?? "";

    if (durationRegex.hasMatch(text)) {
      return text;
    }
  }

  return "";
}

// ======================================================
// ALBUM
// ======================================================

String _year(List? runs) {
  if (runs == null || runs.isEmpty) {
    return "";
  }

  for (final run in runs.reversed) {
    final text = run["text"]?.toString() ?? "";

    if (RegExp(r'^\d{4}$').hasMatch(text)) {
      return text;
    }
  }

  return "";
}

// ======================================================
// VIDEO
// ======================================================

String _views(List? runs) {
  if (runs == null || runs.isEmpty) {
    return "";
  }

  for (final run in runs.reversed) {
    final text = run["text"]?.toString() ?? "";

    final lower = text.toLowerCase();

    if (lower.contains("views") ||
        lower.contains("ditonton") ||
        lower.contains("x ditonton")) {
      return text;
    }
  }

  return "";
}

class TrackRunsMetadata {
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String duration;

  const TrackRunsMetadata({
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    required this.duration,
  });
}

TrackRunsMetadata _parseTrackRuns(List? runs) {
  if (runs == null) {
    return const TrackRunsMetadata(
      artist: "",
      artistId: "",
      album: "",
      albumId: "",
      duration: "",
    );
  }

  String artist = "";
  String artistId = "";

  String album = "";
  String albumId = "";

  String duration = "";

  final durationRegex = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');

  for (final run in runs) {
    final text = run["text"]?.toString() ?? "";

    //-----------------------------------------
    // duration
    //-----------------------------------------

    if (durationRegex.hasMatch(text)) {
      duration = text;
      continue;
    }

    //-----------------------------------------
    // browse endpoint
    //-----------------------------------------

    final endpoint = run["navigationEndpoint"];

    if (endpoint == null) {
      continue;
    }

    final browse = endpoint["browseEndpoint"];

    if (browse == null) {
      continue;
    }

    final browseId = browse["browseId"]?.toString() ?? "";

    final pageType =
        browse["browseEndpointContextSupportedConfigs"]?["browseEndpointContextMusicConfig"]?["pageType"]
            ?.toString() ??
        "";

    if (pageType == "MUSIC_PAGE_TYPE_ARTIST") {
      artist = text;
      artistId = browseId;
    } else if (pageType == "MUSIC_PAGE_TYPE_ALBUM") {
      album = text;
      albumId = browseId;
    }
  }

  return TrackRunsMetadata(
    artist: artist,
    artistId: artistId,
    album: album,
    albumId: albumId,
    duration: duration,
  );
}
