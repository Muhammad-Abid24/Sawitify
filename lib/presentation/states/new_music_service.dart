import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/network/api_client.dart';
import '../../data/model/track_model.dart';
import '../../data/repository/player_repository.dart';
import '../../core/storage/music_storage.dart';

class NewMusicServiceX extends ChangeNotifier {
  static final NewMusicServiceX instance = NewMusicServiceX._();

  NewMusicServiceX._();

  final AudioPlayer player = AudioPlayer();

  List<TrackModel> _playlist = [];

  int _currentIndex = 0;

  bool _shuffleEnabled = false;

  bool _initialized = false;

  bool _nextLock = false;

  Duration? _trackDuration;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  // shuffle playlist
  List<int> _shuffleQueue = [];

  // list queue
  final List<int> _queue = [];
  int _queuePosition = 0;
  List<int> get queue => List.unmodifiable(_queue);

  int get queuePosition => _queuePosition;

  List<TrackModel> get queueTracks {
    return _queue.map((i) => _playlist[i]).toList();
  }

  bool _loadingTrack = false;
  String? _lastError;
  bool get loadingTrack => _loadingTrack;
  String? get lastError => _lastError;

  TrackModel? get currentTrack {
    if (_playlist.isEmpty) {
      return null;
    }

    return _playlist[_currentIndex];
  }

  List<TrackModel> get playlist => _playlist;

  int get currentIndex => _currentIndex;

  //bool get isPlaying => player.playing;

  bool get shuffleEnabled => _shuffleEnabled;

  Duration get trackDuration => _trackDuration ?? Duration.zero;

  bool get hasAudioSource => player.audioSource != null;

  String _playlistName = '';
  String get playlistName => _playlistName;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  StreamSubscription<bool>? _playingSub;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration.music());

    _shuffleEnabled = await MusicStorage.loadShuffle();

    _currentIndex = await MusicStorage.loadCurrentIndex();

    final stored = await MusicStorage.loadPlaylist();

    _playlist = stored.map((e) => TrackModel.fromJson(jsonDecode(e))).toList();

    if (_playlist.isNotEmpty && _currentIndex >= _playlist.length) {
      _currentIndex = 0;
    }

    if (_playlist.isEmpty) {
      final storedTrack = await MusicStorage.loadCurrentTrack();

      if (storedTrack != null) {
        _playlist = [TrackModel.fromJson(jsonDecode(storedTrack))];
        _currentIndex = 0;
      }
    }

    _listenPlayerState();
    _listenTrackCompletion();

    if (_shuffleEnabled) {
      _buildShuffleQueue();
    }
    _buildQueue();
    _moveCurrentTrackToTop();

    _playingSub?.cancel();

    _playingSub = player.playingStream.listen((playing) {
      if (_isPlaying == playing) {
        return;
      }

      _isPlaying = playing;

      notifyListeners();
    });
    notifyListeners();
  }

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

  Future<void> next() async {
    if (_playlist.isEmpty) {
      return;
    }

    // hapus lagu yg selesai

    _removeCurrentTrackFromQueue();

    // queue habis

    if (_queue.isEmpty) {
      _rebuildQueueIfEmpty();
    }

    // lagu berikutnya

    _currentIndex = _queue.first;

    _queuePosition = 0;

    if (_shuffleEnabled) {}

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

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

  Future<void> setShuffle(bool enabled) async {
    _shuffleEnabled = enabled;

    await MusicStorage.saveShuffle(enabled);

    if (enabled) {
      _buildShuffleQueue();
    } else {
      _shuffleQueue.clear();
    }

    _buildQueue();

    notifyListeners();
  }

  void _buildShuffleQueue() {
    _shuffleQueue = List.generate(_playlist.length, (index) => index);

    _shuffleQueue.shuffle(Random());

    final currentPos = _shuffleQueue.indexOf(_currentIndex);

    if (currentPos > 0) {
      final current = _shuffleQueue.removeAt(currentPos);

      _shuffleQueue.insert(0, current);
    }
  }

  Future<void> _savePlaylist() async {
    await MusicStorage.savePlaylist(
      _playlist.map((e) => jsonEncode(e.toJson())).toList(),
    );

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();
  }

  Future<void> _saveCurrentTrack() async {
    if (_playlist.isEmpty) {
      return;
    }

    await MusicStorage.saveCurrentTrack(
      jsonEncode(_playlist[_currentIndex].toJson()),
    );
  }

  Future<void> _restoreCurrentTrack() async {
    final storedTrack = await MusicStorage.loadCurrentTrack();

    if (storedTrack == null) {
      return;
    }

    _playlist = [TrackModel.fromJson(jsonDecode(storedTrack))];

    _currentIndex = 0;

    notifyListeners();
  }

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

  void _setLoading(bool value) {
    if (_loadingTrack == value) {
      return;
    }

    _loadingTrack = value;
    notifyListeners();
  }

  MediaItem? _currentMediaItem;
  Future<void> _updateNowPlaying(TrackModel track) async {
    _currentMediaItem = MediaItem(
      id: track.videoId,

      title: track.title,

      artist: track.artist,

      artUri: Uri.parse(track.thumbnail),

      duration: _trackDuration,
    );
  }

  bool isCurrentQueue(int index) {
    return index == _queuePosition;
  }

  Future<void> playQueue(int queueIndex) async {
    if (queueIndex < 0 || queueIndex >= _queue.length) {
      return;
    }

    // lagu yang sedang diputar
    // jangan diputar ulang

    if (queueIndex == 0) {
      return;
    }

    _currentIndex = _queue[queueIndex];

    // pindahkan ke urutan pertama

    _queue.remove(_currentIndex);

    _queue.insert(0, _currentIndex);

    _queuePosition = 0;

    if (_shuffleEnabled) {}

    await MusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (_queue.length <= 1) {
      return;
    }

    // index 0 (current track)
    // tidak boleh dipindah

    if (oldIndex == 0) {
      return;
    }

    // tidak boleh dipindah
    // ke posisi 0

    if (newIndex == 0) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex--;
    }

    final item = _queue.removeAt(oldIndex);

    _queue.insert(newIndex, item);

    _queuePosition = _queue.indexOf(_currentIndex);

    notifyListeners();
  }

  void _buildQueue() {
    _queue.clear();

    if (_playlist.isEmpty) {
      return;
    }

    if (_shuffleEnabled) {
      _queue.addAll(_shuffleQueue);
    } else {
      _queue.addAll(List.generate(_playlist.length, (i) => i));
    }

    _queuePosition = _queue.indexOf(_currentIndex);

    if (_queuePosition < 0) {
      _queuePosition = 0;
    }
  }

  void _moveCurrentTrackToTop() {
    if (_queue.isEmpty) {
      return;
    }

    final currentPos = _queue.indexOf(_currentIndex);

    if (currentPos <= 0) {
      _queuePosition = 0;

      return;
    }

    final current = _queue.removeAt(currentPos);

    _queue.insert(0, current);

    _queuePosition = 0;
  }

  void _rebuildQueueIfEmpty() {
    if (_queue.isNotEmpty) {
      return;
    }

    if (_shuffleEnabled) {
      _buildShuffleQueue();
    }

    _buildQueue();

    _moveCurrentTrackToTop();
  }

  void _removeCurrentTrackFromQueue() {
    if (_queue.isEmpty) {
      return;
    }

    if (_queue.first == _currentIndex) {
      _queue.removeAt(0);

      return;
    }

    _queue.remove(_currentIndex);
  }

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

  @override
  void dispose() {
    _playerStateSub?.cancel();

    _positionSub?.cancel();

    _playingSub?.cancel();

    player.dispose();

    super.dispose();
  }
}
