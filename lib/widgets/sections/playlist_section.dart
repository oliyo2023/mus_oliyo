import 'package:flutter/material.dart';
import '../../models/playlist.dart';

class PlaylistSection extends StatelessWidget {
  const PlaylistSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟歌单数据
    final playlists = [
      Playlist(
        id: '1',
        name: '华语流行精选',
        description: '最受欢迎的华语流行歌曲',
        coverArt: 'https://via.placeholder.com/300',
        songs: [],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Playlist(
        id: '2',
        name: '深夜电台',
        description: '适合深夜聆听的音乐',
        coverArt: 'https://via.placeholder.com/300',
        songs: [],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Playlist(
        id: '3',
        name: '运动健身',
        description: '充满活力的运动音乐',
        coverArt: 'https://via.placeholder.com/300',
        songs: [],
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
      ),
      Playlist(
        id: '4',
        name: '轻松学习',
        description: '专注学习时的背景音乐',
        coverArt: 'https://via.placeholder.com/300',
        songs: [],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '推荐歌单',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // 查看更多歌单
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return GestureDetector(
              onTap: () {
                _openPlaylist(context, playlist);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getPlaylistColor(index).withValues(alpha: 0.8),
                              _getPlaylistColor(index),
                            ],
                          ),
                        ),
                        child: playlist.coverArt != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  playlist.coverArt!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.queue_music,
                                      color: Colors.white,
                                      size: 48,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.queue_music,
                                color: Colors.white,
                                size: 48,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist.description ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getPlaylistColor(int index) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    // 打开歌单详情页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开歌单: ${playlist.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}