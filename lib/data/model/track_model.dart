class TrackModel {
  /// Video YouTube Music
  final String videoId;

  /// Judul lagu
  final String title;

  /// Nama artis
  final String artist;

  /// BrowseId Artist (UC...)
  final String? artistId;

  /// Nama album
  final String? album;

  /// BrowseId Album (MPRE...)
  final String? albumId;

  /// Thumbnail lagu / album
  final String thumbnail;

  /// Durasi (04:31)
  final String duration;

  const TrackModel({
    required this.videoId,
    required this.title,
    required this.artist,
    this.artistId,
    this.album,
    this.albumId,
    required this.thumbnail,
    required this.duration,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      videoId: (json["videoId"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      artist: (json["artist"] ?? "").toString(),
      artistId: json["artistId"]?.toString(),
      album: json["album"]?.toString(),
      albumId: json["albumId"]?.toString(),
      thumbnail: (json["thumbnail"] ?? "").toString(),
      duration: (json["duration"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "videoId": videoId,
      "title": title,
      "artist": artist,
      "artistId": artistId,
      "album": album,
      "albumId": albumId,
      "thumbnail": thumbnail,
      "duration": duration,
    };
  }

  TrackModel copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    String? thumbnail,
    String? duration,
  }) {
    return TrackModel(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
    );
  }
}
