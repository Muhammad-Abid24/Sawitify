import 'package:shared_preferences/shared_preferences.dart';

class NewMusicStorage {
  static const String _playlistKey = "music_playlist";
  static const String _currentIndexKey = "music_current_index";
  static const String _shuffleKey = "music_shuffle";
  static const String _currentTrackKey = "music_current_track";

  static Future<void> savePlaylist(List<String> playlistJson) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setStringList(_playlistKey, playlistJson);
  }

  static Future<List<String>> loadPlaylist() async {
    final pref = await SharedPreferences.getInstance();

    return pref.getStringList(_playlistKey) ?? [];
  }

  static Future<void> saveCurrentIndex(int index) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setInt(_currentIndexKey, index);
  }

  static Future<int> loadCurrentIndex() async {
    final pref = await SharedPreferences.getInstance();

    return pref.getInt(_currentIndexKey) ?? 0;
  }

  static Future<void> saveCurrentTrack(String trackJson) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(_currentTrackKey, trackJson);
  }

  static Future<String?> loadCurrentTrack() async {
    final pref = await SharedPreferences.getInstance();

    return pref.getString(_currentTrackKey);
  }

  static Future<void> saveShuffle(bool enabled) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setBool(_shuffleKey, enabled);
  }

  static Future<bool> loadShuffle() async {
    final pref = await SharedPreferences.getInstance();

    return pref.getBool(_shuffleKey) ?? false;
  }

  static Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();

    await pref.remove(_playlistKey);
    await pref.remove(_currentIndexKey);
    await pref.remove(_shuffleKey);
    await pref.remove(_currentTrackKey);
  }
}
