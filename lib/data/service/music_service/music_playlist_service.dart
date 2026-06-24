part of 'music_service.dart';

extension MusicPlaylistService on MusicService {
  // =========================================================
  // PLAYLIST
  // =========================================================

  /// Mengganti playlist aktif.
  ///
  /// Method ini akan:
  /// - Menyimpan playlist baru
  /// - Menentukan lagu awal
  /// - Menyimpan playlist ke storage
  /// - Membangun ulang queue dan shuffle
  /// - Memindahkan lagu aktif ke urutan pertama queue
  Future<void> setPlaylist({
    required List<TrackModel> playlist,
    required int startIndex,
    String? playlistName,
  }) async {
    _playlist = List.from(playlist);

    _playlistName = playlistName ?? 'Unknown Playlist';

    if (_playlist.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    }

    await _savePlaylist();

    if (_shuffleEnabled) {
      _buildShuffleQueue();
    }

    _buildQueue();

    _moveCurrentTrackToTop();

    notifyListeners();
  }

  // =========================================================
  // STORAGE
  // =========================================================

  /// Menyimpan seluruh playlist
  /// ke local storage.
  ///
  /// Method ini juga akan:
  /// - Menyimpan current index
  /// - Menyimpan current track
  Future<void> _savePlaylist() async {
    await MusicStorage.savePlaylist(
      _playlist.map((e) => jsonEncode(e.toJson())).toList(),
    );

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();
  }

  /// Menyimpan lagu yang sedang diputar.
  Future<void> _saveCurrentTrack() async {
    if (_playlist.isEmpty) {
      return;
    }

    await MusicStorage.saveCurrentTrack(
      jsonEncode(_playlist[_currentIndex].toJson()),
    );
  }

  /// Mengembalikan lagu terakhir
  /// yang tersimpan di storage.
  Future<void> _restoreCurrentTrack() async {
    final storedTrack = await MusicStorage.loadCurrentTrack();

    if (storedTrack == null) {
      return;
    }

    _playlist = [TrackModel.fromJson(jsonDecode(storedTrack))];

    _currentIndex = 0;

    notifyListeners();
  }

  // =========================================================
  // CLEAR
  // =========================================================

  /// Menghapus seluruh playlist,
  /// queue dan data playback.
  Future<void> clearPlaylist() async {
    _playlist.clear();

    _currentIndex = 0;

    _shuffleQueue.clear();

    _queue.clear();

    _queuePosition = 0;

    _trackDuration = null;

    await player.stop();

    await MusicStorage.clear();

    notifyListeners();
  }
}
