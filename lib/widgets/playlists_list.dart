import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../services/music_api_service.dart';
import '../screens/playlist_detail_screen.dart';
import 'playlist_card.dart';

class PlaylistsList extends StatelessWidget {
  const PlaylistsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicApiService, bool>(
      selector: (context, service) => service.isAuthenticated,
      builder: (context, isAuthenticated, child) {
        if (!isAuthenticated) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('登录后可查看您的歌单', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return FutureBuilder<List<Playlist>>(
          future: context.read<MusicApiService>().getPlaylists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('加载歌单失败: ${snapshot.error}'));
            }

            final playlists = snapshot.data ?? [];
            if (playlists.isEmpty) {
              return const Center(child: Text('暂无歌单'));
            }

            return Column(
              children: playlists
                  .map(
                    (playlist) => PlaylistCard(
                      title: playlist.name,
                      count: playlist.songs.length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlist: playlist),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}