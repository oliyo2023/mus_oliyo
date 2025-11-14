import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerService, _PlayerControlsState>(
      selector: (context, service) => _PlayerControlsState(
        isShuffle: service.isShuffle,
        isRepeat: service.isRepeat,
        isPlaying: service.isPlaying,
        isLoading: service.isLoading,
      ),
      builder: (context, state, child) {
        final playerService = context.read<AudioPlayerService>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 随机播放
            IconButton(
              onPressed: playerService.toggleShuffle,
              icon: Icon(
                Icons.shuffle,
                color: state.isShuffle
                    ? const Color(0xFF1DB954)
                    : Colors.grey[400],
                size: 28,
              ),
            ),
            // 上一首
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: playerService.playPrevious,
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            // 播放/暂停
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: state.isPlaying
                    ? playerService.pause
                    : playerService.play,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        state.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            // 下一首
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: playerService.playNext,
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            // 循环播放
            IconButton(
              onPressed: playerService.toggleRepeat,
              icon: Icon(
                state.isRepeat ? Icons.repeat_one : Icons.repeat,
                color: state.isRepeat
                    ? const Color(0xFF1DB954)
                    : Colors.grey[400],
                size: 28,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 用于 Selector 的状态类，包含播放控制需要的所有状态
class _PlayerControlsState {
  final bool isShuffle;
  final bool isRepeat;
  final bool isPlaying;
  final bool isLoading;

  const _PlayerControlsState({
    required this.isShuffle,
    required this.isRepeat,
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlayerControlsState &&
          runtimeType == other.runtimeType &&
          isShuffle == other.isShuffle &&
          isRepeat == other.isRepeat &&
          isPlaying == other.isPlaying &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(isShuffle, isRepeat, isPlaying, isLoading);
}