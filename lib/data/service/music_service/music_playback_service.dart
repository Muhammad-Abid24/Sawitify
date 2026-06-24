part of 'music_service.dart';

extension MusicPlaybackService on MusicService {
  // =========================================================
  // PLAYER LISTENER
  // =========================================================

  /// Listener ketika audio selesai diputar.
  ///
  /// Jika ProcessingState.completed,
  /// maka otomatis memutar lagu berikutnya.
  void _listenPlayerState() {
    _playerStateSub?.cancel();

    _playerStateSub = player.playerStateStream.listen((state) async {
      if (state.processingState != ProcessingState.completed) {
        return;
      }

      if (_nextLock) {
        return;
      }

      _nextLock = true;

      try {
        await next();
      } catch (e, s) {
        debugPrint('AUTO NEXT ERROR : $e');

        debugPrint(s.toString());
      } finally {
        _nextLock = false;
      }
    });
  }

  /// Listener posisi audio.
  ///
  /// Digunakan untuk mendeteksi lagu
  /// yang hampir selesai (1 detik sebelum akhir)
  /// kemudian menjalankan auto next.
  void _listenTrackCompletion() {
    _positionSub?.cancel();

    _positionSub = player.positionStream.listen((position) async {
      if (_trackDuration == null) {
        return;
      }

      if (_nextLock) {
        return;
      }

      final target = _trackDuration!.inMilliseconds;

      final current = position.inMilliseconds;

      if (current >= target - 1000) {
        _nextLock = true;

        try {
          await next();
        } finally {
          _nextLock = false;
        }
      }
    });
  }

  // =========================================================
  // TRACK LOADER
  // =========================================================

  /// Mengambil stream URL
  /// dan menyiapkan AudioSource.
  Future<void> _loadTrack(TrackModel track) async {
    debugPrint('TITLE = ${track.title}');

    debugPrint('VIDEO_ID = ${track.videoId}');

    _lastError = null;

    _setLoading(true);

    try {
      await player.stop();

      debugPrint('PLAYING: ${track.title}');

      final ytPlayer = await PlayerRepository(
        ApiClient(),
      ).getPlayer(track.videoId);

      _trackDuration = Duration(
        milliseconds: int.tryParse(ytPlayer.durationMs) ?? 0,
      );

      await _updateNowPlaying(track);

      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(ytPlayer.streamUrl),

          tag: MediaItem(
            id: track.videoId,

            title: track.title,

            artist: track.artist,

            artUri: Uri.parse(track.thumbnail),

            duration: _trackDuration,
          ),
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // PLAY TRACK
  // =========================================================

  /// Memutar lagu berdasarkan index playlist.
  Future<void> playTrack(int index) async {
    debugPrint('INDEX = $index');

    if (_playlist.isEmpty) {
      return;
    }

    if (index < 0 || index >= _playlist.length) {
      return;
    }

    debugPrint('CURRENT = ${_playlist[index].title}');

    debugPrint('VIDEO_ID = ${_playlist[index].videoId}');

    try {
      _currentIndex = index;

      _moveCurrentTrackToTop();

      await _loadTrack(_playlist[_currentIndex]);

      await player.play();

      await MusicStorage.saveCurrentIndex(_currentIndex);

      await _saveCurrentTrack();

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  /// Memutar lagu yang sedang aktif.
  Future<void> playCurrentTrack() async {
    if (_playlist.isEmpty) {
      return;
    }

    try {
      await _loadTrack(_playlist[_currentIndex]);

      await player.play();

      await _saveCurrentTrack();

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  // =========================================================
  // PLAY
  // =========================================================

  /// Menjalankan playback.
  ///
  /// Jika AudioSource belum ada,
  /// maka lagu terakhir akan di-restore.
  Future<void> play() async {
    try {
      _lastError = null;

      if (!_isPlaying) {
        _isPlaying = true;

        notifyListeners();
      }

      if (!hasAudioSource) {
        if (_playlist.isEmpty) {
          await _restoreCurrentTrack();
        }

        if (_playlist.isEmpty) {
          return;
        }

        await _loadTrack(_playlist[_currentIndex]);
      }

      await player.play();

      await _saveCurrentTrack();
    } catch (e, s) {
      _isPlaying = false;

      debugPrint('PLAY ERROR = $e');

      debugPrint(s.toString());

      _lastError = 'Gagal memutar lagu';

      notifyListeners();

      rethrow;
    }
  }

  // =========================================================
  // PAUSE
  // =========================================================

  /// Menghentikan playback sementara.
  Future<void> pause() async {
    try {
      _lastError = null;

      if (_isPlaying) {
        _isPlaying = false;

        notifyListeners();
      }

      await player.pause();
    } catch (e, s) {
      _isPlaying = true;

      debugPrint('PAUSE ERROR = $e');

      debugPrint(s.toString());

      _lastError = 'Gagal menghentikan lagu';

      notifyListeners();

      rethrow;
    }
  }

  // =========================================================
  // TOGGLE PLAY / PAUSE
  // =========================================================

  /// Mengubah status play dan pause.
  Future<void> togglePlayPause() async {
    if (_loadingTrack) {
      return;
    }

    try {
      if (_isPlaying) {
        _isPlaying = false;

        notifyListeners();

        unawaited(player.pause());
      } else {
        _isPlaying = true;

        notifyListeners();

        if (!hasAudioSource) {
          await play();

          return;
        }

        unawaited(player.play());
      }
    } catch (e) {
      debugPrint('TOGGLE ERROR = $e');
    }
  }

  // =========================================================
  // NEXT
  // =========================================================

  /// Memutar lagu berikutnya.
  Future<void> next() async {
    if (_playlist.isEmpty) {
      return;
    }

    _removeCurrentTrackFromQueue();

    if (_queue.isEmpty) {
      _rebuildQueueIfEmpty();
    }

    _currentIndex = _queue.first;

    _queuePosition = 0;

    if (_shuffleEnabled) {}

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

  // =========================================================
  // PREVIOUS
  // =========================================================

  /// Memutar lagu sebelumnya.
  Future<void> previous() async {
    if (_playlist.isEmpty) {
      return;
    }

    _queuePosition--;

    if (_queuePosition < 0) {
      _queuePosition = _queue.length - 1;
    }

    _currentIndex = _queue[_queuePosition];

    _moveCurrentTrackToTop();

    if (_shuffleEnabled) {}

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

  // =========================================================
  // LOADING
  // =========================================================

  /// Mengubah status loading track.
  void _setLoading(bool value) {
    if (_loadingTrack == value) {
      return;
    }

    _loadingTrack = value;

    notifyListeners();
  }

  // =========================================================
  // NOW PLAYING
  // =========================================================

  /// Mengupdate MediaItem
  /// yang sedang diputar.
  Future<void> _updateNowPlaying(TrackModel track) async {
    _currentMediaItem = MediaItem(
      id: track.videoId,

      title: track.title,

      artist: track.artist,

      artUri: Uri.parse(track.thumbnail),

      duration: _trackDuration,
    );
  }

  // =========================================================
  // FORCE KILL
  // =========================================================

  /// Menghentikan dan membersihkan
  /// seluruh state player.
  Future<void> forceKillPlayer() async {
    try {
      await player.stop();
    } catch (_) {}

    try {
      await player.dispose();
    } catch (_) {}

    _playlist.clear();

    _queue.clear();

    _shuffleQueue.clear();

    _currentIndex = 0;

    _queuePosition = 0;

    _trackDuration = null;

    _isPlaying = false;

    notifyListeners();
  }
}
