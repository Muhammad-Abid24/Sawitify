enum SearchSuggestionItemType {
  suggestion,
  song,
  artist,
  album,
  playlist,
  unknown,
}

class SearchSuggestionResponse {
  final List<String> suggestions;
  final List<SearchSuggestionItem> items;

  const SearchSuggestionResponse({
    required this.suggestions,
    required this.items,
  });
}

class SearchSuggestionItem {
  final String id;

  final String? params;

  final String title;

  final String artist;

  final String subtitle;

  final String thumbnail;

  final SearchSuggestionItemType type;

  const SearchSuggestionItem({
    required this.id,
    required this.params,
    required this.artist,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    required this.type,
  });
}
