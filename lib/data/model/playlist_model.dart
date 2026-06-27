import 'track_model.dart';

class PlaylistResponse {
  final String title;
  final String description;
  final String thumbnail;
  final List<TrackModel> tracks;

  PlaylistResponse({
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.tracks,
  });
}
