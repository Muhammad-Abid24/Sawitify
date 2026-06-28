enum SearchItemType { song, artist, album, playlist, unknown }

class SearchResponse {
  final List<SearchItem> artists;
  final List<SearchItem> songs;
  final List<SearchItem> albums;
  final List<SearchItem> playlists;

  const SearchResponse({
    required this.artists,
    required this.songs,
    required this.albums,
    required this.playlists,
  });
}

class SearchItem {
  final String id;
  final String title;
  final String artist;
  final String subtitle;
  final String thumbnail;
  final SearchItemType type;

  const SearchItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.subtitle,
    required this.thumbnail,
    required this.type,
  });
}
