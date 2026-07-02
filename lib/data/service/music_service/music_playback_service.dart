part of 'music_service.dart';

extension MusicPlaybackService on MusicService {
  // =========================================================
  // PLAYER CACHE
  // =========================================================

  /// Mengambil PlayerModel dari cache.
  ///
  /// Jika belum ada maka request hanya dilakukan sekali.
  Future<PlayerModel> _getPlayer(TrackModel track) {
    return _playerCache.putIfAbsent(track.videoId, () async {
      debugPrint('[CACHE] FETCH : ${track.title}');

      return PlayerRepository(ApiClient()).getPlayer(track.videoId);
    });
  }

  /// Preload beberapa lagu berikutnya berdasarkan queue.
  ///
  /// Queue digunakan agar tetap benar ketika shuffle aktif.
  void _preloadQueue([int count = 5]) async {
    if (_queue.isEmpty) {
      return;
    }

    _queueChanged = true;
    if (_isPreloading) return;

    _isPreloading = true;

    try {
      while (_queueChanged) {
        _queueChanged = false;

        final total = min(count, _queue.length);
        final currentIndex = player.currentIndex ?? 0;

        // Mulai dari 1 karena index 0 adalah lagu yang sedang diputar
        for (var i = 1; i < total; i++) {
          if (_queueChanged) break;

          final track = _playlist[_queue[i]];
          final expectedIndex = currentIndex + i;

          bool needToAdd = true;

          if (_playlistAudioSource.sequence.length > expectedIndex) {
            final existingItem = _playlistAudioSource.sequence[expectedIndex].tag as MediaItem;
            if (existingItem.id == track.videoId) {
              needToAdd = false;
            } else {
              // Hapus track yang salah dan semua setelahnya
              while (_playlistAudioSource.sequence.length > expectedIndex) {
                await _playlistAudioSource.removeAt(_playlistAudioSource.sequence.length - 1);
              }
            }
          }

          if (needToAdd) {
            try {
              final ytPlayer = await _getPlayer(track);
              if (_queueChanged) break;

              final currentIdxAfterAwt = player.currentIndex ?? 0;
              final expectedIdxAfterAwt = currentIdxAfterAwt + i;

              if (_playlistAudioSource.sequence.length == expectedIdxAfterAwt) {
                await _playlistAudioSource.add(
                  AudioSource.uri(
                    Uri.parse(ytPlayer.streamUrl),
                    tag: MediaItem(
                      id: track.videoId,
                      title: track.title,
                      artist: track.artist,
                      artUri: Uri.parse(track.thumbnail),
                      duration: Duration(milliseconds: int.tryParse(ytPlayer.durationMs) ?? 0),
                    ),
                  ),
                );
                debugPrint('[QUEUE] ADDED TO AUDIO SOURCE : ${track.title} at $expectedIdxAfterAwt');
              }
            } catch (e, s) {
              _playerCache.remove(track.videoId);
              debugPrint('[CACHE] FAILED : ${track.title}');
              debugPrint(e.toString());
              break;
            }
          }
        }
      }
    } finally {
      _isPreloading = false;
    }
  }

  // =========================================================
  // PLAYER LISTENER
  // =========================================================

  /// Listener ketika lagu selesai diputar.
  ///
  /// Auto next hanya menggunakan ProcessingState.completed.
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
  void _listenCurrentIndex() {
    _currentIndexSub?.cancel();
    _currentIndexSub = player.currentIndexStream.listen((index) {
       _syncStateWithPlayerIndex(index);
    });
  }

  void _syncStateWithPlayerIndex(int? index) {
     if (index == null) return;
     
     final sequence = player.sequence;
     if (sequence == null || index >= sequence.length) return;
     
     final mediaItem = sequence[index].tag as MediaItem;
     final videoId = mediaItem.id;
     
     _trackDuration = mediaItem.duration;

     if (_playlist.isEmpty) return;
     
     if (_playlist[_currentIndex].videoId == videoId) {
         return; 
     }

     final playlistIndex = _playlist.indexWhere((t) => t.videoId == videoId);
     if (playlistIndex != -1) {
         _removeCurrentTrackFromQueue();
         
         if (_queue.isEmpty) {
             _rebuildQueueIfEmpty();
         }

         final qIndex = _queue.indexOf(playlistIndex);
         if (qIndex != -1) {
             _queue.removeAt(qIndex);
             _queue.insert(0, playlistIndex);
         } else {
             _queue.insert(0, playlistIndex);
         }

         _currentIndex = playlistIndex;
         _queuePosition = 0;
         
         _updateNowPlaying(_playlist[_currentIndex]);
         
         MusicStorage.saveCurrentIndex(_currentIndex);
         _saveCurrentTrack();
         
         notifyListeners();
         
         _preloadQueue();
     }
  }

  // =========================================================
  // TRACK LOADER
  // =========================================================

  /// Mengambil stream URL dari cache
  /// kemudian menyiapkan AudioSource.
  Future<void> _loadTrack(TrackModel track) async {
    debugPrint('TITLE = ${track.title}');
    debugPrint('VIDEO_ID = ${track.videoId}');

    _lastError = null;
    _trackDuration = null;
    notifyListeners();

    _setLoading(true);

    try {
      await player.stop();
      try { await player.seek(Duration.zero); } catch (_) {}
      await _playlistAudioSource.clear();

      debugPrint('PLAYING: ${track.title}');

      //------------------------------------------------------
      // CACHE PLAYER
      //------------------------------------------------------

      final ytPlayer = await _getPlayer(track);

      _trackDuration = Duration(
        milliseconds: int.tryParse(ytPlayer.durationMs) ?? 0,
      );

      //------------------------------------------------------
      // NOW PLAYING
      //------------------------------------------------------

      await _updateNowPlaying(track);

      //------------------------------------------------------
      // AUDIO SOURCE
      //------------------------------------------------------

      await _playlistAudioSource.add(
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

      if (player.audioSource != _playlistAudioSource) {
        await player.setAudioSource(_playlistAudioSource);
      }

      //------------------------------------------------------
      // PRELOAD NEXT
      //------------------------------------------------------

      _preloadQueue();
    } catch (e, s) {
      debugPrint('LOAD TRACK ERROR : $e');
      debugPrint(s.toString());

      // Future gagal jangan disimpan
      _playerCache.remove(track.videoId);

      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // PLAY TRACK
  // =========================================================

  /// Memutar lagu berdasarkan index playlist.
  Future<void> playTrack(int index) async {
    if (_playlist.isEmpty) {
      return;
    }

    if (index < 0 || index >= _playlist.length) {
      return;
    }

    try {
      _currentIndex = index;

      _moveCurrentTrackToTop();

      await _loadTrack(_playlist[_currentIndex]);

      await player.play();

      await MusicStorage.saveCurrentIndex(_currentIndex);

      await _saveCurrentTrack();

      notifyListeners();
    } catch (e, s) {
      debugPrint('PLAY TRACK ERROR : $e');
      debugPrint(s.toString());

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
    } catch (e, s) {
      debugPrint('PLAY CURRENT ERROR : $e');
      debugPrint(s.toString());

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

      debugPrint('PLAY ERROR : $e');
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

      debugPrint('PAUSE ERROR : $e');
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
        await pause();
      } else {
        if (!hasAudioSource) {
          await play();
          return;
        }

        _lastError = null;

        _isPlaying = true;

        notifyListeners();

        await player.play();
      }
    } catch (e, s) {
      debugPrint('TOGGLE ERROR : $e');
      debugPrint(s.toString());

      _isPlaying = player.playing;

      notifyListeners();

      rethrow;
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
    
    if (player.hasNext) {
       await player.seekToNext();
       return;
    }

    _removeCurrentTrackFromQueue();

    if (_queue.isEmpty) {
      _rebuildQueueIfEmpty();
    }

    _currentIndex = _queue.first;

    _queuePosition = 0;

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

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

    if (player.hasPrevious) {
        await player.seekToPrevious();
        return;
    }

    _queuePosition--;

    if (_queuePosition < 0) {
      _queuePosition = _queue.length - 1;
    }

    _currentIndex = _queue[_queuePosition];

    _moveCurrentTrackToTop();

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

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
    // -------------------------------
    // Stop playback
    // -------------------------------

    try {
      await player.stop();
      await _playlistAudioSource.clear();
    } catch (_) {}
    // -------------------------------
    // Clear playlist
    // -------------------------------

    _playlist.clear();

    _queue.clear();

    _shuffleQueue.clear();

    // -------------------------------
    // Clear cache
    // -------------------------------

    _playerCache.clear();

    // -------------------------------
    // Reset state
    // -------------------------------

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

    notifyListeners();
  }
}
