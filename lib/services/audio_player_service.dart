import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import 'play_history_service.dart';
import 'music_api_service.dart';

enum PlayerState { stopped, playing, paused, loading, error, buffering }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Song? _currentSong;
  int _currentIndex = 0;
  final List<Song> _playlist = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _bufferedProgress = 0.0;

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
  double get bufferedProgress => _bufferedProgress;

  AudioPlayerService() {
    _initAudioPlayer();
  }

  /// 初始化音频播放器
  Future<void> _initAudioPlayer() async {
    try {
      // 配置音频会话
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // 监听播放器状态变化
      _audioPlayer.playerStateStream.listen((state) {
        // 处理 just_audio 的 PlayerState
        debugPrint('Player state changed: $state');
      });
      _audioPlayer.positionStream.listen(_onPositionChanged);
      _audioPlayer.durationStream.listen(_onDurationChanged);
      _audioPlayer.bufferedPositionStream.listen(_onBufferedPositionChanged);
      _audioPlayer.playingStream.listen(_onPlayingChanged);

      // 监听播放完成
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

      // 设置音频源
      await _setAudioSource(_currentSong!);

      // 开始播放
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放失败: $e');
      _playerState = PlayerState.error;
      notifyListeners();

      // 可以在这里添加用户友好的错误提示
      // 例如：无法播放此歌曲，可能由于网络问题或版权限制
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

    if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.buffering) {
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

    if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.buffering) {
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

  /// 设置音频源
  Future<void> _setAudioSource(Song song) async {
    try {
      AudioSource audioSource;

      if (song.isLocal) {
        // 本地音频文件
        audioSource = AudioSource.file(song.url);
      } else {
        // 对于酷狗API，需要动态获取播放URL
        String? audioUrl = song.url;

        // 如果URL为空或为占位符，尝试从API获取
        if (audioUrl.isEmpty ||
            audioUrl == 'https://example.com/music/song.mp3') {
          final apiService = MusicApiService();
          // 优先使用128kbps版本
          audioUrl = await apiService.getSongUrl(song.hash128 ?? song.id);
          if (audioUrl == null || audioUrl.isEmpty) {
            throw Exception('无法获取歌曲播放URL');
          }
        }

        // 验证URL格式
        if (!audioUrl.startsWith('http://') &&
            !audioUrl.startsWith('https://')) {
          throw Exception('无效的音频URL格式: $audioUrl');
        }

        // 处理HTTP URL - 仅在Web端使用代理解决CORS问题
        if (kIsWeb && audioUrl.startsWith('http://')) {
          // Web端使用代理处理HTTP和CORS问题
          audioUrl = 'https://cors-anywhere.herokuapp.com/$audioUrl';
        }

        final uri = Uri.tryParse(audioUrl);
        if (uri == null) {
          throw Exception('无法解析音频URL: $audioUrl');
        }

        audioSource = AudioSource.uri(uri);
      }

      await _audioPlayer.setAudioSource(audioSource);
    } catch (e) {
      debugPrint('设置音频源失败: $e');
      rethrow;
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
      _bufferedProgress =
          bufferedPosition.inMilliseconds / _duration.inMilliseconds;
      notifyListeners();
    }
  }

  /// 播放状态变化监听
  void _onPlayingChanged(bool playing) {
    if (playing) {
      _playerState = PlayerState.playing;
    } else if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.buffering) {
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
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
