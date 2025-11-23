import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../services/audio_player_service.dart';

class DailyRecommendController extends GetxController {
  final MusicApiService _apiService;
  final AudioPlayerService _audioPlayerService;

  DailyRecommendController(this._apiService, this._audioPlayerService);

  // Observable state
  var songs = <Song>[].obs;
  var isLoading = false.obs;
  var error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadDailyRecommend();
  }

  Future<void> loadDailyRecommend() async {
    try {
      isLoading.value = true;
      error.value = null;

      debugPrint('🎵 开始加载每日推荐...');
      final loadedSongs = await _apiService.getDailyRecommend(limit: 50);
      debugPrint('🎵 成功加载 ${loadedSongs.length} 首每日推荐歌曲');
      debugPrint(
        '🎵 前3首歌曲: ${loadedSongs.take(3).map((s) => s.title).toList()}',
      );

      songs.value = loadedSongs;
    } catch (e) {
      debugPrint('❌ 加载每日推荐失败: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playSong(Song song) async {
    try {
      debugPrint('🎵 准备播放歌曲: ${song.title}');

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

  // Refresh method for pull-to-refresh
  @override
  Future<void> refresh() async {
    await loadDailyRecommend();
  }
}
