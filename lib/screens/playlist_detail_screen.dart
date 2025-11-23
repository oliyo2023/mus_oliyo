import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/music_api_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
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

  void _playAllSongs(BuildContext context) {
    final audioPlayerService = context.read<AudioPlayerService>();

    if (widget.playlist.songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('歌单为空')),
      );
      return;
    }

    audioPlayerService.setPlaylist(widget.playlist.songs);
    audioPlayerService.playSong(widget.playlist.songs.first);
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withValues(alpha: 0.8),
                      Colors.blue.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 歌单封面
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: widget.playlist.coverArt != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.playlist.coverArt!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.queue_music,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.queue_music,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 16),
                    // 歌单名称
                    Text(
                      widget.playlist.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // 歌曲数量和时长
                    Text(
                      '${widget.playlist.songs.length} 首歌曲 · ${_formatDuration(widget.playlist.duration)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // 更多选项
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 播放全部按钮
                  ElevatedButton.icon(
                    onPressed: () => _playAllSongs(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 歌单描述
                  if (widget.playlist.description != null &&
                      widget.playlist.description!.isNotEmpty)
                    Text(
                      widget.playlist.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 24),
                  // 歌曲列表标题
                  Text(
                    '歌曲列表',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          // 歌曲列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = widget.playlist.songs[index];
                return ListTile(
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
                    onPressed: () => _playSong(context, song),
                  ),
                  onTap: () => _playSong(context, song),
                );
              },
              childCount: widget.playlist.songs.length,
            ),
          ),
        ],
      ),
    );
  }
}