import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../services/audio_player_service.dart';

class NewSongsController extends GetxController {
  final MusicApiService _apiService;
  final AudioPlayerService _audioPlayerService;

  NewSongsController(this._apiService, this._audioPlayerService);

  // Observable state
  var songs = <Song>[].obs;
  var isLoading = false.obs;
  var error = Rxn<String>();

  // Cache management
  DateTime? _lastLoadTime;
  static const _cacheDuration = Duration(minutes: 30);

  @override
  void onInit() {
    super.onInit();
    loadNewSongs();
  }

  /// Check if cache is still valid
  bool get _isCacheValid {
    if (_lastLoadTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastLoadTime!) < _cacheDuration;
  }

  /// Load new songs with cache support
  Future<void> loadNewSongs({bool forceRefresh = false}) async {
    // If cache is valid and not forcing refresh, skip loading
    if (!forceRefresh && _isCacheValid && songs.isNotEmpty) {
      debugPrint('🎵 使用缓存的新歌数据 (${songs.length} 首)');
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;

      debugPrint('🎵 开始加载新歌速递...');
      final loadedSongs = await _apiService.getTrendingTracks(limit: 50);
      debugPrint('🎵 成功加载 ${loadedSongs.length} 首新歌');
      debugPrint(
        '🎵 前3首歌曲: ${loadedSongs.take(3).map((s) => s.title).toList()}',
      );

      songs.value = loadedSongs;
      _lastLoadTime = DateTime.now();
      debugPrint('🎵 缓存已更新，过期时间: ${_lastLoadTime!.add(_cacheDuration)}');
    } catch (e) {
      debugPrint('❌ 加载新歌速递失败: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Play a song
  Future<void> playSong(Song song) async {
    try {
      debugPrint('🎵 准备播放歌曲: ${song.title}');

      // 如果歌曲已有URL，直接播放
      if (song.url.isNotEmpty) {
        debugPrint('🎵 使用已有URL播放');
        _audioPlayerService.setPlaylist([song]);
        _audioPlayerService.playSong(song);
        return;
      }

      // 获取播放URL
      final url = await _apiService.getSongUrl(song.hash128 ?? song.id);

      if (url != null && url.isNotEmpty) {
        debugPrint('🎵 获取到播放URL: $url');
        final updatedSong = song.copyWith(url: url);
        _audioPlayerService.setPlaylist([updatedSong]);
        _audioPlayerService.playSong(updatedSong);
      } else {
        debugPrint('❌ 无法获取播放地址');
        throw Exception('无法获取播放地址，可能是VIP歌曲或版权限制');
      }
    } catch (e) {
      debugPrint('❌ 播放失败: $e');
      rethrow;
    }
  }

  /// Refresh method for pull-to-refresh
  @override
  Future<void> refresh() async {
    await loadNewSongs(forceRefresh: true);
  }

  /// Force refresh (e.g., from refresh button)
  Future<void> forceRefresh() async {
    await loadNewSongs(forceRefresh: true);
  }
}
