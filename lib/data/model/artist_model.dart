import 'track_model.dart';

class ArtistResponse {
  final ArtistHeader artist;

  final List<TrackModel> topSongs;

  final List<ArtistAlbum> albums;

  final List<ArtistAlbum> singles;

  final List<ArtistVideo> videos;

  final List<FeaturedOn> featuredOn;
  final List<FeaturedOn> playlistArtist;

  final List<RelatedArtist> relatedArtists;

  const ArtistResponse({
    required this.artist,
    required this.topSongs,
    required this.albums,
    required this.singles,
    required this.videos,
    required this.featuredOn,
    required this.playlistArtist,
    required this.relatedArtists,
  });

  factory ArtistResponse.empty() {
    return ArtistResponse(
      artist: ArtistHeader.empty(),
      topSongs: const [],
      albums: const [],
      singles: const [],
      videos: const [],
      featuredOn: const [],
      playlistArtist: const [],
      relatedArtists: const [],
    );
  }
}

class ArtistHeader {
  final String browseId;

  final String name;

  final String description;

  final String subscribers;

  final String monthlyListeners;

  final String thumbnail;

  const ArtistHeader({
    required this.browseId,
    required this.name,
    required this.description,
    required this.subscribers,
    required this.monthlyListeners,
    required this.thumbnail,
  });

  factory ArtistHeader.empty() {
    return const ArtistHeader(
      browseId: '',
      name: '',
      description: '',
      subscribers: '',
      monthlyListeners: '',
      thumbnail: '',
    );
  }
}

class ArtistAlbum {
  final String browseId;

  final String title;

  final String year;

  final String thumbnail;

  const ArtistAlbum({
    required this.browseId,
    required this.title,
    required this.year,
    required this.thumbnail,
  });
}

class ArtistVideo {
  final String videoId;

  final String title;

  final String thumbnail;

  final String views;

  const ArtistVideo({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.views,
  });
}

class FeaturedOn {
  final String browseId;

  final String title;
  final String subtitle;

  final String thumbnail;

  const FeaturedOn({
    required this.browseId,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
  });
}

class RelatedArtist {
  final String browseId;

  final String name;

  final String thumbnail;

  final String subscribers;

  const RelatedArtist({
    required this.browseId,
    required this.name,
    required this.thumbnail,
    required this.subscribers,
  });
}
