import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../../services/music_api_service.dart';
import '../../widgets/sections/recent_section.dart';
import '../../widgets/sections/popular_section.dart';
import '../../widgets/sections/playlist_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildDailyRecommendSection() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '每日推荐',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/daily-recommend');
                },
                child: const Text('查看更多'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Consumer<MusicApiService>(
              builder: (context, apiService, child) {
                return FutureBuilder<List<Song>>(
                  future: apiService.getDailyRecommend(limit: 6),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('加载每日推荐失败: ${snapshot.error}'));
                    }

                    final songs = snapshot.data ?? [];
                    if (songs.isEmpty) {
                      return const Center(child: Text('暂无每日推荐'));
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: songs
                          .map((song) => _buildDailyRecommendCard(song))
                          .toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendCard(Song song) {
    return Builder(
      builder: (context) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withValues(alpha: 0.8),
              Colors.purple.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _playSong(context, song),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playSong(BuildContext context, Song song) async {
    final audioPlayerService = context.read<AudioPlayerService>();
    final apiService = context.read<MusicApiService>();

    // 如果歌曲已有URL，直接播放
    if (song.url.isNotEmpty &&
        song.url !=
            'https://example.com/music/daily${song.id.replaceAll('daily', '')}.mp3') {
      audioPlayerService.setPlaylist([song]);
      audioPlayerService.playSong(song);
      return;
    }

    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 异步获取URL
      final url = await apiService.getSongUrl(song.hash128 ?? song.id);

      // 关闭加载提示
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (url != null && url.isNotEmpty) {
        final updatedSong = song.copyWith(url: url);
        audioPlayerService.setPlaylist([updatedSong]);
        audioPlayerService.playSong(updatedSong);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取播放地址，可能是VIP歌曲或版权限制')),
          );
        }
      }
    } catch (e) {
      // 关闭加载提示
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  Widget _buildNewSongsSection() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '新歌速递',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/new-songs');
                },
                child: const Text('查看更多'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildNewSongCard('最新热门', Icons.trending_up, Colors.red),
                _buildNewSongCard('华语新歌', Icons.language, Colors.blue),
                _buildNewSongCard('欧美新歌', Icons.music_note, Colors.green),
                _buildNewSongCard('日韩新歌', Icons.queue_music, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSongCard(String title, IconData icon, Color color) {
    return Builder(
      builder: (context) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pushNamed('/new-songs');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyRecommendSection(),
            const SizedBox(height: 32),
            _buildNewSongsSection(),
            const SizedBox(height: 32),
            const RecentSection(),
            const SizedBox(height: 32),
            const PopularSection(),
            const SizedBox(height: 32),
            const PlaylistSection(),
          ],
        ),
      ),
    );
  }
}