import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import '../song_card.dart';

class RecentSection extends StatelessWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟最近播放的歌曲数据
    final recentSongs = [
      Song(
        id: '1',
        title: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song1.mp3',
        duration: 269,
      ),
      Song(
        id: '2',
        title: '起风了',
        artist: '买辣椒也用券',
        album: '起风了',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song2.mp3',
        duration: 325,
      ),
      Song(
        id: '3',
        title: '孤勇者',
        artist: '陈奕迅',
        album: '孤勇者',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song3.mp3',
        duration: 268,
      ),
      Song(
        id: '4',
        title: '漠河舞厅',
        artist: '柳爽',
        album: '漠河舞厅',
        coverArt: 'https://via.placeholder.com/200',
        url: 'music/song4.mp3',
        duration: 332,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最近播放',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // 查看更多最近播放
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
            itemCount: recentSongs.length,
            itemBuilder: (context, index) {
              final song = recentSongs[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == recentSongs.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () {
                    _playSong(context, [song, ...recentSongs], 0);
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
