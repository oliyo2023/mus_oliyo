import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import '../models/song.dart';
import 'play_history_service.dart';
import 'music_api_service.dart';

enum AudioPlayerState { stopped, playing, paused, loading, error, buffering }

class AudioPlayerService extends ChangeNotifier {
  final audioplayers.AudioPlayer _audioPlayer = audioplayers.AudioPlayer();
  AudioPlayerState _playerState = AudioPlayerState.stopped;
  Song? _currentSong;
  int _currentIndex = 0;
  final List<Song> _playlist = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  bool _isRepeat = false;

  PlayHistoryService? _historyService;

  AudioPlayerState get playerState => _playerState;
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  List<Song> get playlist => List.unmodifiable(_playlist);
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isPlaying => _playerState == AudioPlayerState.playing;
  bool get isPaused => _playerState == AudioPlayerState.paused;
  bool get isLoading => _playerState == AudioPlayerState.loading;
  bool get isBuffering => _playerState == AudioPlayerState.buffering;

  AudioPlayerService() {
    _initAudioPlayer();
  }

  /// 初始化音频播放器
  Future<void> _initAudioPlayer() async {
    try {
      // 监听播放器状态变化
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('Player state changed: $state');
        switch (state) {
          case audioplayers.PlayerState.playing:
            _playerState = AudioPlayerState.playing;
            break;
          case audioplayers.PlayerState.paused:
            _playerState = AudioPlayerState.paused;
            break;
          case audioplayers.PlayerState.stopped:
            _playerState = AudioPlayerState.stopped;
            break;
          case audioplayers.PlayerState.completed:
            // 播放完成时，设置为停止状态
            _playerState = AudioPlayerState.stopped;
            break;
          default:
            // 对于未知状态，保持当前状态
            break;
        }
        notifyListeners();
      });

      _audioPlayer.onPositionChanged.listen((position) {
        _position = position;
        notifyListeners();
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        _duration = duration;
        notifyListeners();
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        if (_isRepeat) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.resume();
        } else {
          playNext();
        }
      });
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
      _playerState = AudioPlayerState.error;
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
      _playerState = AudioPlayerState.loading;
      notifyListeners();

      // 设置音频源
      await _setAudioSource(_currentSong!);

      // 开始播放
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('播放失败: $e');
      _playerState = AudioPlayerState.error;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _playerState = AudioPlayerState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _playerState = AudioPlayerState.stopped;
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
      // 随机播放模式：随机选择下一首歌曲
      _currentIndex = Random().nextInt(_playlist.length);
    } else {
      // 顺序播放模式
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      if (_currentIndex == 0 && !_isRepeat) {
        await stop();
        return;
      }
    }

    _currentSong = _playlist[_currentIndex];
    _position = Duration.zero;

    if (_playerState == AudioPlayerState.playing) {
      await play();
    } else {
      notifyListeners();
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      // 随机播放模式：随机选择上一首歌曲（实际上还是随机）
      _currentIndex = Random().nextInt(_playlist.length);
    } else {
      // 顺序播放模式
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }

    _currentSong = _playlist[_currentIndex];
    _position = Duration.zero;

    if (_playerState == AudioPlayerState.playing) {
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
      String audioUrl = song.url;

      // 如果URL为空或为占位符，尝试从API获取
      if (audioUrl.isEmpty || audioUrl == 'https://example.com/music/song.mp3') {
        // 调用API服务获取URL
        final apiService = MusicApiService();
        audioUrl = await apiService.getSongUrl(song.hash128 ?? song.id) ?? '';
        if (audioUrl.isEmpty) {
          throw Exception('无法获取歌曲播放URL');
        }
      }

      // 验证URL格式
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        throw Exception('无效的音频URL格式: $audioUrl');
      }

      // 处理HTTP URL - 仅在Web端使用代理解决CORS问题
      if (kIsWeb && audioUrl.startsWith('http://')) {
        audioUrl = 'https://cors-anywhere.herokuapp.com/$audioUrl';
      }

      await _audioPlayer.setSourceUrl(audioUrl);
    } catch (e) {
      debugPrint('设置音频源失败: $e');
      rethrow;
    }
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