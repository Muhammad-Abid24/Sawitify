part of 'music_service.dart';

extension MusicPlaylistService on MusicService {
  // =========================================================
  // PLAYLIST
  // =========================================================

  /// Mengganti playlist aktif.
  ///
  /// Method ini akan:
  /// - Menyimpan playlist baru
  /// - Menghapus cache stream playlist lama
  /// - Menentukan lagu awal
  /// - Menyimpan playlist
  /// - Membangun ulang queue
  Future<void> setPlaylist({
    required List<TrackModel> playlist,
    required int startIndex,
    String? playlistName,
  }) async {
    // ----------------------------------------
    // Stop playback lama
    // ----------------------------------------

    await player.stop();
    try { await player.seek(Duration.zero); } catch (_) {}
    await _playlistAudioSource.clear();

    _trackDuration = null;

    // ----------------------------------------
    // Hapus cache playlist lama
    // ----------------------------------------

    _playerCache.clear();

    // ----------------------------------------
    // Playlist
    // ----------------------------------------

    _playlist = List<TrackModel>.from(playlist);

    _playlistName = playlistName ?? 'Unknown Playlist';

    if (_playlist.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    }

    // ----------------------------------------
    // Queue
    // ----------------------------------------

    if (_shuffleEnabled) {
      _buildShuffleQueue();
    } else {
      _shuffleQueue.clear();
    }

    _buildQueue();

    _moveCurrentTrackToTop();

    // ----------------------------------------
    // Storage
    // ----------------------------------------

    await _savePlaylist();

    notifyListeners();
  }

  // =========================================================
  // STORAGE
  // =========================================================

  /// Menyimpan playlist.
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

  /// Mengembalikan playlist terakhir
  /// dari storage.
  Future<void> _restoreCurrentTrack() async {
    final storedTrack = await MusicStorage.loadCurrentTrack();

    if (storedTrack == null) {
      return;
    }

    _playlist = [TrackModel.fromJson(jsonDecode(storedTrack))];

    _currentIndex = 0;

    _buildQueue();

    _moveCurrentTrackToTop();

    notifyListeners();
  }

  // =========================================================
  // CLEAR
  // =========================================================

  /// Menghapus seluruh playlist.
  Future<void> clearPlaylist() async {
    await player.stop();
    await _playlistAudioSource.clear();

    _playlist.clear();

    _playerCache.clear();

    _shuffleQueue.clear();

    _queue.clear();

    _currentIndex = 0;

    _queuePosition = 0;

    _trackDuration = null;

    _currentMediaItem = null;

    _playlistName = '';

    _lastError = null;

    _loadingTrack = false;

    _isPlaying = false;

    _nextLock = false;
    
    _isPreloading = false;
    
    _queueChanged = false;

    await MusicStorage.clear();

    notifyListeners();
  }
}
