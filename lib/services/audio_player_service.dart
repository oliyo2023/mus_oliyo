import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'play_history_service.dart';

enum PlayerState { stopped, playing, paused, loading, error }

class AudioPlayerService extends ChangeNotifier {
  PlayerState _playerState = PlayerState.stopped;
  Song? _currentSong;
  int _currentIndex = 0;
  final List<Song> _playlist = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;

  PlayHistoryService? _historyService;

  // 模拟播放器服务，因为没有网络连接下载依赖
  // 在实际项目中，这里会使用 just_audio 包

  PlayerState get playerState => _playerState;
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  List<Song> get playlist => List.unmodifiable(_playlist);
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isLoading => _playerState == PlayerState.loading;

  /// 设置播放历史服务
  void setHistoryService(PlayHistoryService service) {
    _historyService = service;
  }

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist.clear();
    _playlist.addAll(songs);
    _currentIndex = startIndex;
    if (songs.isNotEmpty) {
      _currentSong = songs[startIndex];
      _duration = Duration(seconds: songs[startIndex].duration ?? 0);
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentSong == null) return;

    _playerState = PlayerState.loading;
    notifyListeners();

    // 模拟加载时间
    await Future.delayed(const Duration(milliseconds: 500));

    _playerState = PlayerState.playing;
    notifyListeners();

    // 模拟播放进度
    _simulatePlayback();
  }

  Future<void> pause() async {
    _playerState = PlayerState.paused;
    notifyListeners();
  }

  Future<void> stop() async {
    _playerState = PlayerState.stopped;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    _position = position;
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      if (_currentIndex == 0 && !_isRepeat) {
        await stop();
        return;
      }
    }

    _currentSong = _playlist[_currentIndex];
    _duration = Duration(seconds: _currentSong!.duration ?? 0);
    _position = Duration.zero;

    if (_playerState == PlayerState.playing) {
      await play();
    } else {
      notifyListeners();
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentSong = _playlist[_currentIndex];
    _duration = Duration(seconds: _currentSong!.duration ?? 0);
    _position = Duration.zero;

    if (_playerState == PlayerState.playing) {
      await play();
    } else {
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    int index = _playlist.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _currentIndex = index;
      _currentSong = song;
      _duration = Duration(seconds: song.duration ?? 0);
      _position = Duration.zero;

      // 记录到播放历史
      _historyService?.addToHistory(song);

      await play();
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void _simulatePlayback() {
    if (_playerState != PlayerState.playing) return;

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_playerState == PlayerState.playing && _position < _duration) {
        _position = Duration(seconds: _position.inSeconds + 1);
        notifyListeners();
        _simulatePlayback();
      } else if (_position >= _duration && _duration > Duration.zero) {
        if (_isRepeat) {
          _position = Duration.zero;
          _simulatePlayback();
        } else {
          playNext();
        }
      }
    });
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}