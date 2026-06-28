import 'package:flutter/rendering.dart';
import 'package:sawitify/core/network/api_client.dart';
import 'package:sawitify/core/network/service_config.dart';

import '../model/search_model.dart';

class SearchRepository {
  SearchRepository(this.api);

  final ApiClient api;

  static const String searchArtistParams =
      "Eg-KAQwIABAAGAAgASgAMABqChAEEAMQCRAFEAo%3D";
  static const String searchSongParams =
      "Eg-KAQwIARAAGAAgACgAMABqChAEEAMQCRAFEAo%3D";
  static const String searchAlbumParams =
      "Eg-KAQwIABAAGAEgACgAMABqChAEEAMQCRAFEAo%3D";

  Future<Map<String, dynamic>> _request(String query, String params) async {
    return await api.apiSearch.search("json", ServiceConfig.apiKey!, {
          "context": {
            "capabilities": {},
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20260623.13.00",
              "hl": "en",
              "gl": "ID",
            },
            "user": {"enableSafetyMode": false},
          },
          "query": query,
          "params": params,
        })
        as Map<String, dynamic>;
  }

  Future<List<SearchItem>> searchArtists(String query) async {
    final json = await _request(query, searchArtistParams);
    return _parseArtists(json);
  }

  Future<List<SearchItem>> searchSongs(String query) async {
    final json = await _request(query, searchSongParams);
    return _parseSongs(json);
  }

  Future<List<SearchItem>> searchAlbums(String query) async {
    final json = await _request(query, searchAlbumParams);
    return _parseAlbums(json);
  }

  List<SearchItem> _parseArtists(Map<String, dynamic> json) {
    final List<SearchItem> items = [];

    final tabs =
        json["contents"]?["tabbedSearchResultsRenderer"]?["tabs"] as List? ??
        [];

    for (final tab in tabs) {
      final sections =
          tab["tabRenderer"]?["content"]?["sectionListRenderer"]?["contents"]
              as List? ??
          [];

      for (final section in sections) {
        final shelf = section["musicShelfRenderer"];

        if (shelf == null) continue;

        final rows = shelf["contents"] as List? ?? [];

        for (final row in rows) {
          final renderer = row["musicResponsiveListItemRenderer"];

          if (renderer == null) continue;

          final flex = renderer["flexColumns"] as List? ?? [];

          if (flex.isEmpty) continue;

          //--------------------------------------------------
          // TITLE
          //--------------------------------------------------

          final titleRuns =
              flex[0]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                  as List? ??
              [];

          final title = titleRuns.isNotEmpty
              ? titleRuns.first["text"]?.toString() ?? ""
              : "";

          //--------------------------------------------------
          // SUBTITLE
          //--------------------------------------------------

          String subtitle = "";

          if (flex.length > 1) {
            final runs =
                flex[1]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                    as List? ??
                [];

            subtitle = runs.map((e) => e["text"]?.toString() ?? "").join();
          }

          //--------------------------------------------------
          // THUMBNAIL
          //--------------------------------------------------

          String thumbnail = "";

          final thumbnails =
              renderer["thumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
                  as List? ??
              [];

          if (thumbnails.isNotEmpty) {
            thumbnail = thumbnails.last["url"]?.toString() ?? "";
          }

          //--------------------------------------------------
          // ID
          //--------------------------------------------------

          String id = "";

          Map<String, dynamic>? nav =
              renderer["navigationEndpoint"] as Map<String, dynamic>?;

          nav ??= titleRuns.isNotEmpty
              ? titleRuns.first["navigationEndpoint"] as Map<String, dynamic>?
              : null;

          if (nav != null) {
            id = nav["browseEndpoint"]?["browseId"]?.toString() ?? "";
          }

          items.add(
            SearchItem(
              id: id,
              title: title,
              artist: title,
              subtitle: subtitle,
              thumbnail: thumbnail,
              type: SearchItemType.artist,
            ),
          );
        }
      }
    }

    return items;
  }

  List<SearchItem> _parseSongs(Map<String, dynamic> json) {
    final List<SearchItem> items = [];

    final tabs =
        json["contents"]?["tabbedSearchResultsRenderer"]?["tabs"] as List? ??
        [];

    for (final tab in tabs) {
      final sections =
          tab["tabRenderer"]?["content"]?["sectionListRenderer"]?["contents"]
              as List? ??
          [];

      for (final section in sections) {
        final shelf = section["musicShelfRenderer"];

        if (shelf == null) continue;

        final rows = shelf["contents"] as List? ?? [];

        for (final row in rows) {
          final renderer = row["musicResponsiveListItemRenderer"];

          if (renderer == null) continue;

          final flex = renderer["flexColumns"] as List? ?? [];

          if (flex.isEmpty) continue;

          //--------------------------------------------------
          // TITLE
          //--------------------------------------------------

          final titleRuns =
              flex[0]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                  as List? ??
              [];

          final title = titleRuns.isNotEmpty
              ? titleRuns.first["text"]?.toString() ?? ""
              : "";

          //--------------------------------------------------
          // SUBTITLE
          //--------------------------------------------------

          String subtitle = "";
          String artist = "";

          if (flex.length > 1) {
            final runs =
                flex[1]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                    as List? ??
                [];

            subtitle = runs.map((e) => e["text"]?.toString() ?? "").join();

            for (final run in runs) {
              final endpoint = run["navigationEndpoint"];

              if (endpoint == null) continue;

              final pageType =
                  endpoint["browseEndpoint"]?["browseEndpointContextSupportedConfigs"]?["browseEndpointContextMusicConfig"]?["pageType"]
                      ?.toString();

              if (pageType == "MUSIC_PAGE_TYPE_ARTIST") {
                artist = run["text"]?.toString() ?? "";
                break;
              }
            }
          }

          //--------------------------------------------------
          // THUMBNAIL
          //--------------------------------------------------

          String thumbnail = "";

          final thumbnails =
              renderer["thumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
                  as List? ??
              [];

          if (thumbnails.isNotEmpty) {
            thumbnail = thumbnails.last["url"]?.toString() ?? "";
          }

          //--------------------------------------------------
          // ID
          //--------------------------------------------------

          String id = "";

          Map<String, dynamic>? nav =
              renderer["navigationEndpoint"] as Map<String, dynamic>?;

          nav ??= titleRuns.isNotEmpty
              ? titleRuns.first["navigationEndpoint"] as Map<String, dynamic>?
              : null;

          if (nav != null) {
            id = nav["watchEndpoint"]?["videoId"]?.toString() ?? "";
          }

          items.add(
            SearchItem(
              id: id,
              title: title,
              artist: artist,
              subtitle: subtitle,
              thumbnail: thumbnail,
              type: SearchItemType.song,
            ),
          );
        }
      }
    }

    return items;
  }

  List<SearchItem> _parseAlbums(Map<String, dynamic> json) {
    final List<SearchItem> items = [];

    final tabs =
        json["contents"]?["tabbedSearchResultsRenderer"]?["tabs"] as List? ??
        [];

    for (final tab in tabs) {
      final sections =
          tab["tabRenderer"]?["content"]?["sectionListRenderer"]?["contents"]
              as List? ??
          [];

      for (final section in sections) {
        final shelf = section["musicShelfRenderer"];

        if (shelf == null) continue;

        final rows = shelf["contents"] as List? ?? [];

        for (final row in rows) {
          final renderer = row["musicResponsiveListItemRenderer"];

          if (renderer == null) continue;

          final flex = renderer["flexColumns"] as List? ?? [];

          if (flex.isEmpty) continue;

          //--------------------------------------------------
          // TITLE
          //--------------------------------------------------

          final titleRuns =
              flex[0]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                  as List? ??
              [];

          final title = titleRuns.isNotEmpty
              ? titleRuns.first["text"]?.toString() ?? ""
              : "";

          //--------------------------------------------------
          // SUBTITLE
          //--------------------------------------------------

          String subtitle = "";
          String artist = "";

          if (flex.length > 1) {
            final runs =
                flex[1]["musicResponsiveListItemFlexColumnRenderer"]?["text"]?["runs"]
                    as List? ??
                [];

            subtitle = runs.map((e) => e["text"]?.toString() ?? "").join();

            for (final run in runs) {
              final endpoint = run["navigationEndpoint"];

              if (endpoint == null) continue;

              final pageType =
                  endpoint["browseEndpoint"]?["browseEndpointContextSupportedConfigs"]?["browseEndpointContextMusicConfig"]?["pageType"]
                      ?.toString();

              if (pageType == "MUSIC_PAGE_TYPE_ARTIST") {
                artist = run["text"]?.toString() ?? "";
                break;
              }
            }
          }

          //--------------------------------------------------
          // THUMBNAIL
          //--------------------------------------------------

          String thumbnail = "";

          final thumbnails =
              renderer["thumbnail"]?["musicThumbnailRenderer"]?["thumbnail"]?["thumbnails"]
                  as List? ??
              [];

          if (thumbnails.isNotEmpty) {
            thumbnail = thumbnails.last["url"]?.toString() ?? "";
          }

          //--------------------------------------------------
          // ID
          //--------------------------------------------------

          String id = "";

          Map<String, dynamic>? nav =
              renderer["navigationEndpoint"] as Map<String, dynamic>?;

          nav ??= titleRuns.isNotEmpty
              ? titleRuns.first["navigationEndpoint"] as Map<String, dynamic>?
              : null;

          if (nav != null) {
            id = nav["browseEndpoint"]?["browseId"]?.toString() ?? "";
          }

          items.add(
            SearchItem(
              id: id,
              title: title,
              artist: artist,
              subtitle: subtitle,
              thumbnail: thumbnail,
              type: SearchItemType.album,
            ),
          );
        }
      }
    }

    return items;
  }
}
