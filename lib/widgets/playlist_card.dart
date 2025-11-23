import 'package:flutter/material.dart';

class PlaylistCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.title,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.queue_music),
        ),
        title: Text(title),
        subtitle: Text('$count 首歌曲'),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}