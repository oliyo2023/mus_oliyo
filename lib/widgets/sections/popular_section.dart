import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

  void _playSong(BuildContext context, List<Song> songs, int index) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.setPlaylist(songs, startIndex: index);
    playerService.play();
  }
}