import 'package:flutter/cupertino.dart';
import 'package:sawitify/core/utils/dump_json.dart';

import '../../../data/model/playlist_model.dart';
import '../../../data/model/track_model.dart';
import 'track_response.dart';

PlaylistResponse parsePlaylist(Map<String, dynamic> json) {
  dumpJson(json);

  debugPrint("========== PLAYLIST ==========");

  //----------------------------------------------------------
  // VARIABLES
  //----------------------------------------------------------

  String title = "";
  String description = "";
  String thumbnail = "";
  String playlistId = "";

  String artist = "";
  String? artistId = "";

  final tracks = <TrackModel>[];

  //----------------------------------------------------------
  // ROOT
  //----------------------------------------------------------

  final root = json["contents"]?["twoColumnBrowseResultsRenderer"];

  if (root == null) {
    return PlaylistResponse(
      title: "",
      description: "",
      thumbnail: "",
      tracks: [],
    );
  }

  //----------------------------------------------------------
  // HEADER
  //----------------------------------------------------------

  Map<String, dynamic>? header;

  header = json["header"]?["musicResponsiveHeaderRenderer"];

  header ??= root["header"]?["musicResponsiveHeaderRenderer"];

  if (header != null) {
    //------------------------------------------------------
    // ARTIST
    //------------------------------------------------------

    final strapline =
        header["straplineTextOne"]?["runs"] as List? ??
        header["subtitle"]?["runs"] as List? ??
        [];

    for (final run in strapline) {
      final browse = run["navigationEndpoint"]?["browseEndpoint"];

      if (browse == null) {
        continue;
      }

      final pageType =
          browse["browseEndpointContextSupportedConfigs"]?["browseEndpointContextMusicConfig"]?["pageType"]
              ?.toString() ??
          "";

      final browseId = browse["browseId"]?.toString() ?? "";

      if (pageType == "MUSIC_PAGE_TYPE_ARTIST" ||
          pageType == "MUSIC_PAGE_TYPE_USER_CHANNEL" ||
          browseId.startsWith("UC")) {
        artist = run["text"]?.toString() ?? "";
        artistId = browseId;
        break;
      }
    }

    //------------------------------------------------------
    // TITLE
    //------------------------------------------------------

    title = header["title"]?["runs"]?[0]?["text"]?.toString() ?? "";

    //------------------------------------------------------
    // DESCRIPTION
    //------------------------------------------------------

    description =
        header["description"]?["runs"]?.map((e) => e["text"]).join("") ?? "";

    //------------------------------------------------------
    // THUMBNAIL
    //------------------------------------------------------

    List thumbs =
        header["thumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"] ??
        [];

    if (thumbs.isEmpty) {
      thumbs =
          header["straplineThumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"] ??
          [];
    }

    if (thumbs.isNotEmpty) {
      thumbnail = thumbs.last["url"]?.toString() ?? "";
    }

    //------------------------------------------------------
    // PLAYLIST ID
    //------------------------------------------------------

    final buttons = header["buttons"] as List? ?? [];

    for (final button in buttons) {
      final watch =
          button["musicPlayButtonRenderer"]?["playNavigationEndpoint"]?["watchEndpoint"];

      if (watch == null) continue;

      playlistId = watch["playlistId"]?.toString() ?? playlistId;

      if (playlistId.isNotEmpty) {
        break;
      }
    }
  }

  //----------------------------------------------------------
  // FIND TRACK SHELF
  //----------------------------------------------------------

  List<dynamic> items = [];

  void readSections(List sections) {
    for (final section in sections) {
      //------------------------------------------------------
      // musicPlaylistShelfRenderer
      //------------------------------------------------------

      final playlistShelf = section["musicPlaylistShelfRenderer"];

      if (playlistShelf != null) {
        playlistId = playlistShelf["playlistId"]?.toString() ?? playlistId;

        final contents = playlistShelf["contents"] as List? ?? [];

        if (contents.isNotEmpty) {
          items = contents;
          return;
        }
      }

      //------------------------------------------------------
      // musicShelfRenderer
      //------------------------------------------------------

      final musicShelf = section["musicShelfRenderer"];

      if (musicShelf != null) {
        final contents = musicShelf["contents"] as List? ?? [];

        if (contents.isNotEmpty) {
          items = contents;
          return;
        }
      }
    }
  }

  //----------------------------------------------------------
  // secondaryContents
  //----------------------------------------------------------

  final secondary =
      root["secondaryContents"]?["sectionListRenderer"]?["contents"] as List? ??
      [];

  readSections(secondary);

  //----------------------------------------------------------
  // tabs fallback
  //----------------------------------------------------------

  if (items.isEmpty) {
    final tabSections =
        root["tabs"]?[0]?["tabRenderer"]?["content"]?["sectionListRenderer"]?["contents"]
            as List? ??
        [];

    readSections(tabSections);
  }

  //----------------------------------------------------------
  // PARSE TRACKS
  //----------------------------------------------------------

  for (final item in items) {
    if (item["continuationItemRenderer"] != null) {
      continue;
    }

    final track = parseTrack(item);

    if (track == null) {
      continue;
    }

    tracks.add(track);
  }

  //----------------------------------------------------------
  // FALLBACK TITLE
  //----------------------------------------------------------

  if (title.trim().isEmpty && tracks.isNotEmpty) {
    title = tracks.first.album?.isNotEmpty == true
        ? tracks.first.album!
        : tracks.first.title;
  }

  //----------------------------------------------------------
  // FALLBACK DESCRIPTION
  //----------------------------------------------------------

  if (description.trim().isEmpty && tracks.isNotEmpty) {
    description = tracks.first.artist;
  }

  //----------------------------------------------------------
  // FALLBACK THUMBNAIL
  //----------------------------------------------------------

  if (thumbnail.trim().isEmpty && tracks.isNotEmpty) {
    thumbnail = tracks.first.thumbnail;
  }

  //----------------------------------------------------------
  // NORMALIZE THUMBNAIL
  //----------------------------------------------------------

  if (thumbnail.isNotEmpty) {
    thumbnail = thumbnail
        .replaceAll("w60-h60", "w600-h600")
        .replaceAll("w120-h120", "w600-h600")
        .replaceAll("=s60", "=s600")
        .replaceAll("=s120", "=s600");
  }

  //----------------------------------------------------------
  // DEBUG
  //----------------------------------------------------------

  debugPrint("--------------------------------");
  debugPrint("PLAYLIST");
  debugPrint("--------------------------------");
  debugPrint("TITLE       : $title");
  debugPrint("DESCRIPTION : $description");
  debugPrint("PLAYLIST ID : $playlistId");
  debugPrint("THUMBNAIL   : $thumbnail");
  debugPrint("TRACK COUNT : ${tracks.length}");
  debugPrint("--------------------------------");

  if (tracks.isNotEmpty) {
    final first = tracks.first;

    debugPrint("FIRST TRACK");
    debugPrint("--------------------------------");
    debugPrint("TITLE      : ${first.title}");
    debugPrint("ARTIST     : ${first.artist}");
    debugPrint("ALBUM      : ${first.album}");
    debugPrint("VIDEO ID   : ${first.videoId}");
    debugPrint("DURATION   : ${first.duration}");
    debugPrint("THUMBNAIL  : ${first.thumbnail}");
    debugPrint("--------------------------------");
  }

  //----------------------------------------------------------
  // RESULT
  //----------------------------------------------------------

  return PlaylistResponse(
    title: title,
    description: description,
    thumbnail: thumbnail,
    tracks: tracks,
  );
}
