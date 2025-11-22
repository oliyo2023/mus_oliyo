import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../services/audio_player_service.dart';

class DailyRecommendScreen extends StatefulWidget {
  const DailyRecommendScreen({super.key});

  @override
  State<DailyRecommendScreen> createState() => _DailyRecommendScreenState();
}

class _DailyRecommendScreenState extends State<DailyRecommendScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailyRecommend();
  }

  Future<void> _loadDailyRecommend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<MusicApiService>();
      final songs = await apiService.getDailyRecommend(limit: 50); // 获取更多每日推荐
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日推荐'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDailyRecommend,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDailyRecommend,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(child: Text('暂无每日推荐数据'));
    }

    return RefreshIndicator(
      onRefresh: _loadDailyRecommend,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                child: song.coverArt != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song.coverArt!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.music_note, color: Colors.grey),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSong(song),
              ),
              onTap: () => _playSong(song),
            ),
          );
        },
      ),
    );
  }

  Future<void> _playSong(Song song) async {
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
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (url != null && url.isNotEmpty) {
        final updatedSong = song.copyWith(url: url);
        audioPlayerService.setPlaylist([updatedSong]);
        audioPlayerService.playSong(updatedSong);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取播放地址，可能是VIP歌曲或版权限制')),
          );
        }
      }
    } catch (e) {
      // 关闭加载提示
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
      }
    }
  }
}
