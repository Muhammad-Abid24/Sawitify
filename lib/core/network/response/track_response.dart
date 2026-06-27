import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../../data/model/track_model.dart';

bool _printedRenderer = false;

TrackModel? parseTrack(Map<String, dynamic> item) {
  try {
    //----------------------------------------------------------
    // RENDERER
    //----------------------------------------------------------

    final renderer =
        item["musicResponsiveListItemRenderer"] as Map<String, dynamic>?;

    debugPrint("========================================");
    debugPrint("TRACK TITLE RAW");
    debugPrint(
      renderer?["flexColumns"]?[1]?["musicResponsiveListItemFlexColumnRenderer"]?["text"]
          .toString(),
    );
    debugPrint("========================================");

    if (renderer == null) {
      return null;
    }

    //----------------------------------------------------------
    // DEBUG
    //----------------------------------------------------------

    if (!_printedRenderer) {
      _printedRenderer = true;
      debugPrint(const JsonEncoder.withIndent("  ").convert(renderer));
    }

    //----------------------------------------------------------
    // VARIABLES
    //----------------------------------------------------------

    String videoId = "";
    String title = "";

    String artist = "";
    String artistId = "";

    String album = "";
    String albumId = "";

    String thumbnail = "";
    String duration = "";

    //----------------------------------------------------------
    // VIDEO ID
    //----------------------------------------------------------

    videoId = renderer["playlistItemData"]?["videoId"]?.toString() ?? "";

    if (videoId.isEmpty) {
      videoId =
          renderer["navigationEndpoint"]?["watchEndpoint"]?["videoId"]
              ?.toString() ??
          "";
    }

    if (videoId.isEmpty) {
      videoId =
          renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["content"]?["musicPlayButtonRenderer"]?["playNavigationEndpoint"]?["watchEndpoint"]?["videoId"]
              ?.toString() ??
          "";
    }

    if (videoId.isEmpty) {
      return null;
    }

    //----------------------------------------------------------
    // FLEX COLUMNS
    //----------------------------------------------------------

    final flexColumns = renderer["flexColumns"] as List? ?? [];

    debugPrint("========== FLEX COLUMNS ==========");
    debugPrint(const JsonEncoder.withIndent("  ").convert(flexColumns));

    //----------------------------------------------------------
    // TITLE
    //----------------------------------------------------------

    for (final column in flexColumns) {
      final runs =
          column["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
              as List? ??
          [];

      debugPrint("RUNS TYPE = ${runs.runtimeType}");
      debugPrint("RUNS = $runs");

      if (runs.isEmpty) {
        continue;
      }

      final value = runs.map((e) => e["text"]?.toString() ?? "").join().trim();

      if (value.isEmpty) {
        continue;
      }

      title = value;
      break;
    }

    if (title.isEmpty) {
      return null;
    }

    //----------------------------------------------------------
    // ARTIST + ALBUM
    //----------------------------------------------------------

    for (final column in flexColumns) {
      final runs =
          column["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
              as List? ??
          [];

      for (final raw in runs) {
        final run = Map<String, dynamic>.from(raw);
        debugPrint("--------------------------------");
        debugPrint(const JsonEncoder.withIndent("  ").convert(run));

        final text = run["text"]?.toString().trim() ?? "";

        if (text.isEmpty || text == "•") {
          continue;
        }

        final endpoint = run["navigationEndpoint"] as Map<String, dynamic>?;

        if (endpoint == null) {
          continue;
        }

        final browse = endpoint["browseEndpoint"] as Map<String, dynamic>?;

        if (browse == null) {
          continue;
        }

        final browseId = browse["browseId"]?.toString() ?? "";

        final pageType =
            browse["browseEndpointContextSupportedConfigs"]?["browseEndpointContextMusicConfig"]?["pageType"]
                ?.toString() ??
            "";

        //------------------------------------------------------
        // ARTIST
        //------------------------------------------------------

        if (pageType == "MUSIC_PAGE_TYPE_ARTIST" ||
            pageType == "MUSIC_PAGE_TYPE_USER_CHANNEL" ||
            browseId.startsWith("UC")) {
          artist = text;
          artistId = browseId;
          continue;
        }

        //------------------------------------------------------
        // ALBUM
        //------------------------------------------------------

        if (pageType == "MUSIC_PAGE_TYPE_ALBUM" ||
            browseId.startsWith("MPRE")) {
          album = text;
          albumId = browseId;
        }
      }
    }

    //----------------------------------------------------------
    // PART 2
    //----------------------------------------------------------
    //----------------------------------------------------------
    // THUMBNAIL
    //----------------------------------------------------------

    List<dynamic> thumbs =
        renderer["thumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
            as List? ??
        [];

    if (thumbs.isEmpty) {
      thumbs =
          renderer["thumbnail"]?["croppedSquareThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
              as List? ??
          [];
    }

    if (thumbs.isEmpty) {
      thumbs =
          renderer["background"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
              as List? ??
          [];
    }

    if (thumbs.isEmpty) {
      thumbs =
          renderer["straplineThumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
              as List? ??
          [];
    }

    if (thumbs.isEmpty) {
      thumbs =
          renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["thumbnail"]?["thumbnails"]
              as List? ??
          [];
    }

    if (thumbs.isNotEmpty) {
      thumbnail = thumbs.last["url"]?.toString() ?? "";
    }

    //----------------------------------------------------------
    // NORMALIZE THUMBNAIL
    //----------------------------------------------------------

    if (thumbnail.isNotEmpty) {
      thumbnail = thumbnail
          .replaceAll("w60-h60", "w600-h600")
          .replaceAll("w120-h120", "w600-h600")
          .replaceAll("w180-h180", "w600-h600")
          .replaceAll("=s60", "=s600")
          .replaceAll("=s120", "=s600")
          .replaceAll("=s180", "=s600");
    }

    //----------------------------------------------------------
    // DURATION
    //----------------------------------------------------------

    final fixedColumns = renderer["fixedColumns"] as List? ?? [];

    for (final column in fixedColumns) {
      final runs =
          column["musicResponsiveListItemFixedColumnRenderer"]?["text"]?["runs"]
              as List? ??
          [];

      if (runs.isEmpty) {
        continue;
      }

      final value = runs.map((e) => e["text"]?.toString() ?? "").join().trim();

      if (value.isEmpty) {
        continue;
      }

      duration = value;
      break;
    }

    //----------------------------------------------------------
    // ACCESSIBILITY FALLBACK
    //----------------------------------------------------------

    if (duration.isEmpty) {
      final label =
          renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["content"]?["musicPlayButtonRenderer"]?["accessibilityPlayData"]?["accessibilityData"]?["label"]
              ?.toString() ??
          "";

      if (label.isNotEmpty) {
        final match = RegExp(r'(\d+:\d+|\d+\.\d+)').firstMatch(label);

        if (match != null) {
          duration = match.group(1) ?? "";
        }
      }
    }

    //----------------------------------------------------------
    // NORMALIZE DURATION
    //----------------------------------------------------------

    if (duration.contains(".")) {
      final split = duration.split(".");

      if (split.length == 2) {
        duration = "${split[0]}:${split[1].padLeft(2, "0")}";
      }
    }

    //----------------------------------------------------------
    // PART 3
    //----------------------------------------------------------
    //----------------------------------------------------------
    // ARTIST FALLBACK
    //----------------------------------------------------------

    if (artist.isEmpty) {
      final label =
          renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["content"]?["musicPlayButtonRenderer"]?["accessibilityPlayData"]?["accessibilityData"]?["label"]
              ?.toString() ??
          renderer["overlay"]?["musicItemThumbnailOverlayRenderer"]?["content"]?["musicPlayButtonRenderer"]?["accessibilityPauseData"]?["accessibilityData"]?["label"]
              ?.toString() ??
          "";

      final index = label.lastIndexOf(" - ");

      if (index != -1) {
        artist = label.substring(index + 3).trim();
      }

      debugPrint("ACCESSIBILITY : $label");
      debugPrint("ARTIST        : $artist");
    }

    //----------------------------------------------------------
    // THUMBNAIL FALLBACK
    //----------------------------------------------------------

    if (thumbnail.isEmpty) {
      thumbnail = "https://i.ytimg.com/vi/$videoId/hqdefault.jpg";
    }

    //----------------------------------------------------------
    // NORMALIZE
    //----------------------------------------------------------

    artist = artist.trim();
    artistId = artistId.trim();

    album = album.trim();
    albumId = albumId.trim();

    thumbnail = thumbnail.trim();
    duration = duration.trim();

    //----------------------------------------------------------
    // DEBUG
    //----------------------------------------------------------

    debugPrint("--------------------------------");
    debugPrint("TRACK");
    debugPrint("--------------------------------");
    debugPrint("TITLE      : $title");
    debugPrint("VIDEO ID   : $videoId");
    debugPrint("ARTIST     : $artist");
    debugPrint("ARTIST ID  : $artistId");
    debugPrint("ALBUM      : $album");
    debugPrint("ALBUM ID   : $albumId");
    debugPrint("DURATION   : $duration");
    debugPrint("THUMBNAIL  : $thumbnail");
    debugPrint("--------------------------------");

    //----------------------------------------------------------
    // RESULT
    //----------------------------------------------------------

    return TrackModel(
      videoId: videoId,
      title: title,
      artist: artist,
      artistId: artistId.isEmpty ? null : artistId,
      album: album.isEmpty ? null : album,
      albumId: albumId.isEmpty ? null : albumId,
      thumbnail: thumbnail,
      duration: duration,
    );
  } catch (e, s) {
    debugPrint("--------------------------------");
    debugPrint("TRACK PARSE ERROR");
    debugPrint("--------------------------------");
    debugPrint(e.toString());
    debugPrint(s.toString());
    debugPrint("--------------------------------");

    return null;
  }
}
