part of 'music_service.dart';

extension MusicQueueService on MusicService {
  // =========================================================
  // SHUFFLE
  // =========================================================

  /// Mengaktifkan atau menonaktifkan shuffle.
  ///
  /// Method ini juga akan:
  /// - Menyimpan status shuffle
  /// - Membuat ulang shuffle queue
  /// - Membangun ulang queue
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

    _preloadQueue();
  }

  /// Membuat urutan acak playlist.
  ///
  /// Lagu yang sedang diputar
  /// akan dipindahkan ke urutan pertama.
  void _buildShuffleQueue() {
    _shuffleQueue = List.generate(_playlist.length, (index) => index);

    _shuffleQueue.shuffle(Random());

    final currentPos = _shuffleQueue.indexOf(_currentIndex);

    if (currentPos > 0) {
      final current = _shuffleQueue.removeAt(currentPos);

      _shuffleQueue.insert(0, current);
    }
  }

  // =========================================================
  // QUEUE
  // =========================================================

  /// Mengecek apakah item queue
  /// adalah lagu yang sedang diputar.
  bool isCurrentQueue(int index) {
    return index == _queuePosition;
  }

  /// Memutar lagu berdasarkan
  /// urutan queue.
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

  /// Mengubah posisi item
  /// di dalam queue.
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

    _preloadQueue();
  }

  // =========================================================
  // BUILD QUEUE
  // =========================================================

  /// Membangun ulang queue.
  ///
  /// Jika shuffle aktif maka
  /// queue menggunakan shuffle queue.
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

  /// Memindahkan lagu yang sedang
  /// diputar ke urutan pertama queue.
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

  /// Membangun ulang queue
  /// ketika queue habis.
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

  /// Menghapus lagu yang sudah
  /// selesai diputar dari queue.
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
}
