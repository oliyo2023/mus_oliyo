import 'package:flutter/material.dart';
import '../../widgets/playlists_list.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '音乐库',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    title: const Text('喜欢的音乐'),
                    subtitle: const Text('收藏的歌曲'),
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    title: const Text('最近播放'),
                    subtitle: const Text('播放历史'),
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    title: const Text('本地音乐'),
                    subtitle: const Text('手机中的音乐'),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '我的歌单',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  // 歌单列表组件
                  const PlaylistsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}