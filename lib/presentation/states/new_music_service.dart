import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/network/api_client.dart';
import '../../data/model/track_model.dart';
import '../../data/repository/player_repository.dart';
import '../../core/storage/new_music_storage.dart';

class NewMusicService extends ChangeNotifier {
  static final NewMusicService instance = NewMusicService._();

  NewMusicService._();

  final AudioPlayer player = AudioPlayer();

  List<TrackModel> _playlist = [];

  int _currentIndex = 0;

  bool _shuffleEnabled = false;

  bool _initialized = false;

  bool _nextLock = false;

  Duration? _trackDuration;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  List<int> _shuffleQueue = [];

  int _shufflePosition = 0;

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

  bool get isPlaying => player.playing;

  bool get shuffleEnabled => _shuffleEnabled;

  Duration get trackDuration => _trackDuration ?? Duration.zero;

  bool get hasAudioSource => player.audioSource != null;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration.music());

    _shuffleEnabled = await NewMusicStorage.loadShuffle();

    _currentIndex = await NewMusicStorage.loadCurrentIndex();

    final stored = await NewMusicStorage.loadPlaylist();

    _playlist = stored.map((e) => TrackModel.fromJson(jsonDecode(e))).toList();

    if (_playlist.isNotEmpty && _currentIndex >= _playlist.length) {
      _currentIndex = 0;
    }

    if (_playlist.isEmpty) {
      final storedTrack = await NewMusicStorage.loadCurrentTrack();

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
  }) async {
    _playlist = List.from(playlist);

    if (_playlist.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    }

    await _savePlaylist();

    if (_shuffleEnabled) {
      _buildShuffleQueue();
    }

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

      await player.setUrl(ytPlayer.streamUrl);
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

      await _loadTrack(_playlist[_currentIndex]);

      await player.play();

      await NewMusicStorage.saveCurrentIndex(_currentIndex);

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

      notifyListeners();
    } catch (e, s) {
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

      await player.pause();

      notifyListeners();
    } catch (e, s) {
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
      if (player.playing) {
        await pause();
      } else {
        await play();
      }
    } catch (e) {
      debugPrint('TOGGLE ERROR = $e');
    }
  }

  Future<void> next() async {
    if (_playlist.isEmpty) {
      return;
    }

    if (_shuffleEnabled) {
      _shufflePosition++;

      if (_shufflePosition >= _shuffleQueue.length) {
        _buildShuffleQueue();
        _shufflePosition = 0;
      }

      _currentIndex = _shuffleQueue[_shufflePosition];
    } else {
      _currentIndex++;

      if (_currentIndex >= _playlist.length) {
        _currentIndex = 0;
      }
    }

    await NewMusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) {
      return;
    }

    if (_shuffleEnabled) {
      _shufflePosition--;

      if (_shufflePosition < 0) {
        _shufflePosition = _shuffleQueue.length - 1;
      }

      _currentIndex = _shuffleQueue[_shufflePosition];
    } else {
      _currentIndex--;

      if (_currentIndex < 0) {
        _currentIndex = _playlist.length - 1;
      }
    }

    await NewMusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();

    notifyListeners();

    await playCurrentTrack();
  }

  Future<void> setShuffle(bool enabled) async {
    _shuffleEnabled = enabled;

    await NewMusicStorage.saveShuffle(enabled);

    if (enabled) {
      _buildShuffleQueue();
    }

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

    _shufflePosition = 0;
  }

  Future<void> _savePlaylist() async {
    await NewMusicStorage.savePlaylist(
      _playlist.map((e) => jsonEncode(e.toJson())).toList(),
    );

    await NewMusicStorage.saveCurrentIndex(_currentIndex);

    await _saveCurrentTrack();
  }

  Future<void> _saveCurrentTrack() async {
    if (_playlist.isEmpty) {
      return;
    }

    await NewMusicStorage.saveCurrentTrack(
      jsonEncode(_playlist[_currentIndex].toJson()),
    );
  }

  Future<void> _restoreCurrentTrack() async {
    final storedTrack = await NewMusicStorage.loadCurrentTrack();

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

    _shufflePosition = 0;

    _trackDuration = null;

    await player.stop();

    await NewMusicStorage.clear();

    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_loadingTrack == value) {
      return;
    }

    _loadingTrack = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    player.dispose();

    super.dispose();
  }
}
