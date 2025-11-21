import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import '../song_card.dart';

class PopularSection extends StatelessWidget {
  const PopularSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟热门歌曲数据
    final popularSongs = [
      Song(
        id: '5',
        title: '花海',
        artist: '周杰伦',
        album: '魔杰座',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song5.mp3',
        duration: 266,
      ),
      Song(
        id: '6',
        title: '错位时空',
        artist: '艾辰',
        album: '错位时空',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song6.mp3',
        duration: 226,
      ),
      Song(
        id: '7',
        title: '白月光与朱砂痣',
        artist: '大籽',
        album: '白月光与朱砂痣',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song7.mp3',
        duration: 237,
      ),
      Song(
        id: '8',
        title: '晚风',
        artist: '伍佰',
        album: '白鸽',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song8.mp3',
        duration: 318,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '热门推荐',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // 查看更多热门歌曲
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularSongs.length,
            itemBuilder: (context, index) {
              final song = popularSongs[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == popularSongs.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () {
                    _playSong(context, [song, ...popularSongs], 0);
                  },
                  child: SongCard(song: song),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playSong(
    BuildContext context,
    List<Song> songs,
    int index,
  ) async {
    final playerService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );
    final apiService = Provider.of<MusicApiService>(context, listen: false);
    final song = songs[index];

    // 如果歌曲已有URL，直接播放
    if (song.url.isNotEmpty && !song.url.startsWith('music/')) {
      playerService.setPlaylist(songs, startIndex: index);
      playerService.play();
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
        // 更新列表中的歌曲信息
        final updatedSongs = List<Song>.from(songs);
        updatedSongs[index] = updatedSong;

        playerService.setPlaylist(updatedSongs, startIndex: index);
        playerService.play();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
      }
    }
  }
}
