import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../models/song.dart';
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

  void _playSong(BuildContext context, List<Song> songs, int index) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.setPlaylist(songs, startIndex: index);
    playerService.play();
  }
}