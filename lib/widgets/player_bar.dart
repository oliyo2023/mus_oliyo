import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Selector 只监听当前歌曲变化，避免进度条变化导致整个组件重建
    return Selector<AudioPlayerService, Song?>(
      selector: (context, service) => service.currentSong,
      builder: (context, currentSong, child) {
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PlayerScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end).chain(
                    CurveTween(curve: curve),
                  );

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进度条 - 使用单独的 Selector 只监听进度变化
                const PlayerProgressBar(),
                const SizedBox(height: 8),
                // 播放控制栏 - 使用单独的 Selector 只监听播放状态变化
                const PlayerControlBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 进度条组件 - 只监听进度相关状态
class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerService, double>(
      selector: (context, service) => service.progress,
      builder: (context, progress, child) {
        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}

// 播放控制栏组件 - 使用自定义选择器同时监听多个状态
class PlayerControlBar extends StatelessWidget {
  const PlayerControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerService, _PlayerControlState>(
      selector: (context, service) => _PlayerControlState(
        currentSong: service.currentSong,
        isPlaying: service.isPlaying,
      ),
      builder: (context, state, child) {
        if (state.currentSong == null) return const SizedBox.shrink();

        final playerService = context.read<AudioPlayerService>();

        return Row(
          children: [
            // 专辑封面
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              child: state.currentSong!.coverArt != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        state.currentSong!.coverArt!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.music_note,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.currentSong!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.currentSong!.artist,
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 播放控制按钮
            IconButton(
              onPressed: state.isPlaying ? playerService.pause : playerService.play,
              icon: Icon(
                state.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 用于 Selector 的状态类，包含播放控制栏需要的所有状态
class _PlayerControlState {
  final Song? currentSong;
  final bool isPlaying;

  const _PlayerControlState({
    required this.currentSong,
    required this.isPlaying,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlayerControlState &&
          runtimeType == other.runtimeType &&
          currentSong == other.currentSong &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode => Object.hash(currentSong, isPlaying);
}