import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/music_storage.dart';
import '../../model/track_model.dart';
import '../../repository/player_repository.dart';

part 'music_playback_service.dart';

part 'music_queue_service.dart';

part 'music_playlist_service.dart';

class MusicService extends ChangeNotifier {
  static final MusicService instance = MusicService._();

  MusicService._();

  // ======================================================
  // AUDIO PLAYER
  // ======================================================

  final AudioPlayer player = AudioPlayer();

  // ======================================================
  // PLAYLIST
  // ======================================================

  List<TrackModel> _playlist = [];

  int _currentIndex = 0;

  String _playlistName = '';

  Duration? _trackDuration;

  // ======================================================
  // PLAYER STATE
  // ======================================================

  bool _initialized = false;

  bool _isPlaying = false;

  bool _loadingTrack = false;

  bool _nextLock = false;

  bool _shuffleEnabled = false;

  String? _lastError;

  // ======================================================
  // QUEUE
  // ======================================================

  List<int> _shuffleQueue = [];

  final List<int> _queue = [];

  int _queuePosition = 0;

  // ======================================================
  // MEDIA ITEM
  // ======================================================

  MediaItem? _currentMediaItem;

  // ======================================================
  // SUBSCRIPTIONS
  // ======================================================

  StreamSubscription<PlayerState>? _playerStateSub;

  StreamSubscription<Duration>? _positionSub;

  StreamSubscription<bool>? _playingSub;

  // ======================================================
  // GETTERS
  // ======================================================

  List<int> get queue => List.unmodifiable(_queue);

  int get queuePosition => _queuePosition;

  List<TrackModel> get queueTracks {
    return _queue.map((i) => _playlist[i]).toList();
  }

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

  bool get shuffleEnabled => _shuffleEnabled;

  bool get hasAudioSource => player.audioSource != null;

  Duration get trackDuration => _trackDuration ?? Duration.zero;

  String get playlistName => _playlistName;

  bool get isPlaying => _isPlaying;

  /// Inisialisasi service.
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
      await _restoreCurrentTrack();
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

  /// Membersihkan seluruh resource.
  @override
  void dispose() {
    _playerStateSub?.cancel();

    _positionSub?.cancel();

    _playingSub?.cancel();

    player.dispose();

    super.dispose();
  }
}
