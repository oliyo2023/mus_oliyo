import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class PlayerPlaylistSection extends StatelessWidget {
  const PlayerPlaylistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        if (playerService.playlist.isEmpty) {
          return const Center(
            child: Text(
              '播放列表为空',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: playerService.playlist.length,
          itemBuilder: (context, index) {
            final song = playerService.playlist[index];
            final isCurrentSong = index == playerService.currentIndex;

            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                child: isCurrentSong
                    ? Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      )
                    : song.coverArt != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.coverArt!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                  size: 20,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                            size: 20,
                          ),
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  color: isCurrentSong
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                song.artist,
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
              trailing: isCurrentSong
                  ? Icon(
                      Icons.equalizer,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    )
                  : IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showSongOptions(context, song);
                      },
                    ),
              onTap: () {
                if (!isCurrentSong) {
                  playerService.playSong(song);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('立即播放'),
              onTap: () {
                Navigator.pop(context);
                // 播放选中歌曲的逻辑
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
                // 添加到歌单的逻辑
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('添加到喜欢'),
              onTap: () {
                Navigator.pop(context);
                // 添加到喜欢的逻辑
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // 分享的逻辑
              },
            ),
          ],
        ),
      ),
    );
  }
}