import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import 'play_history_service.dart';
import 'music_cache_service.dart';

/// 播放器状态枚举
enum PlayerState { stopped, playing, paused, loading, error, buffering }

/// 集成缓存功能的音频播放器服务
class CachedAudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicCacheService _cacheService;
  
  PlayerState _playerState = PlayerState.stopped;
  Song? _currentSong;
  int _currentIndex = 0;
  final List<Song> _playlist = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _bufferedProgress = 0.0;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  PlayHistoryService? _historyService;

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
  bool get isBuffering => _playerState == PlayerState.buffering;
  bool get isDownloading => _isDownloading;
  double get bufferedProgress => _bufferedProgress;
  double get downloadProgress => _downloadProgress;
  MusicCacheService get cacheService => _cacheService;

  CachedAudioPlayerService(this._cacheService) {
    _initAudioPlayer();
  }

  /// 初始化音频播放器
  Future<void> _initAudioPlayer() async {
    try {
      // 配置音频会话
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // 监听播放器状态变化
      _audioPlayer.positionStream.listen(_onPositionChanged);
      _audioPlayer.durationStream.listen(_onDurationChanged);
      _audioPlayer.bufferedPositionStream.listen(_onBufferedPositionChanged);
      _audioPlayer.playingStream.listen(_onPlayingChanged);
      _audioPlayer.processingStateStream.listen(_onProcessingStateChanged);
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
      _playerState = PlayerState.error;
      notifyListeners();
    }
  }

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
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentSong == null) return;

    try {
      _playerState = PlayerState.loading;
      notifyListeners();

      // 设置音频源（优先使用缓存）
      await _setAudioSource(_currentSong!);
      
      // 开始播放
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放失败: $e');
      _playerState = PlayerState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _playerState = PlayerState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('停止失败: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('跳转失败: $e');
    }
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
    _position = Duration.zero;

    if (_playerState == PlayerState.playing || _playerState == PlayerState.buffering) {
      await play();
    } else {
      notifyListeners();
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentSong = _playlist[_currentIndex];
    _position = Duration.zero;

    if (_playerState == PlayerState.playing || _playerState == PlayerState.buffering) {
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

  /// 预下载歌曲到缓存
  Future<void> preloadSong(Song song) async {
    if (_cacheService.isCached(song.id)) {
      debugPrint('歌曲已缓存，无需预下载: ${song.title}');
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // 模拟下载进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _downloadProgress = i / 100;
        notifyListeners();
      }

      // 实际下载
      final cachedPath = await _cacheService.downloadAndCache(song);
      
      if (cachedPath != null) {
        debugPrint('预下载成功: ${song.title}');
      } else {
        debugPrint('预下载失败: ${song.title}');
      }
    } catch (e) {
      debugPrint('预下载失败: $e');
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// 设置音频源（优先使用缓存）
  Future<void> _setAudioSource(Song song) async {
    try {
      AudioSource audioSource;
      
      // 检查是否有本地缓存
      final cachedPath = _cacheService.getCachedFilePath(song.id);
      
      if (cachedPath != null && File(cachedPath).existsSync()) {
        // 使用缓存文件
        debugPrint('使用缓存播放: ${song.title}');
        audioSource = AudioSource.file(cachedPath);
      } else if (song.isLocal) {
        // 本地音频文件
        debugPrint('播放本地文件: ${song.title}');
        audioSource = AudioSource.file(song.url);
      } else {
        // 网络音频文件
        debugPrint('在线播放: ${song.title}');
        audioSource = AudioSource.uri(Uri.parse(song.url));
        
        // 后台缓存
        _cacheInBackground(song);
      }

      await _audioPlayer.setAudioSource(audioSource);
    } catch (e) {
      debugPrint('设置音频源失败: $e');
      rethrow;
    }
  }

  /// 后台缓存歌曲
  Future<void> _cacheInBackground(Song song) async {
    try {
      // 避免重复下载
      if (_cacheService.isCached(song.id)) return;
      
      debugPrint('后台缓存: ${song.title}');
      await _cacheService.downloadAndCache(song);
    } catch (e) {
      debugPrint('后台缓存失败: $e');
    }
  }

  /// 播放位置变化监听
  void _onPositionChanged(Duration position) {
    _position = position;
    notifyListeners();
  }

  /// 音频时长变化监听
  void _onDurationChanged(Duration? duration) {
    if (duration != null) {
      _duration = duration;
      notifyListeners();
    }
  }

  /// 缓冲位置变化监听
  void _onBufferedPositionChanged(Duration bufferedPosition) {
    if (_duration.inMilliseconds > 0) {
      _bufferedProgress = bufferedPosition.inMilliseconds / _duration.inMilliseconds;
      notifyListeners();
    }
  }

  /// 播放状态变化监听
  void _onPlayingChanged(bool playing) {
    if (playing) {
      _playerState = PlayerState.playing;
    } else if (_playerState == PlayerState.playing || _playerState == PlayerState.buffering) {
      _playerState = PlayerState.paused;
    }
    notifyListeners();
  }

  /// 处理状态变化监听
  void _onProcessingStateChanged(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        _playerState = PlayerState.stopped;
        break;
      case ProcessingState.loading:
        _playerState = PlayerState.loading;
        break;
      case ProcessingState.buffering:
        _playerState = PlayerState.buffering;
        break;
      case ProcessingState.ready:
        // 保持当前状态
        break;
      case ProcessingState.completed:
        if (_isRepeat) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else {
          playNext();
        }
        return;
    }
    notifyListeners();
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
