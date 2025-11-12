import 'package:flutter/material.dart';

class LyricsSection extends StatelessWidget {
  const LyricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟歌词数据
    final lyrics = [
      {'time': 0, 'text': '♪ 暂无歌词 ♪'},
      {'time': 10, 'text': '请添加歌词文件'},
      {'time': 20, 'text': '或使用在线歌词服务'},
      {'time': 30, 'text': '享受音乐的美好时光'},
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final lyric = lyrics[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Text(
                lyric['text'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: index == 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: 0.7),
                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}