import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 随机播放
            IconButton(
              onPressed: playerService.toggleShuffle,
              icon: Icon(
                Icons.shuffle,
                color: playerService.isShuffle
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
                onPressed: playerService.isPlaying
                    ? playerService.pause
                    : playerService.play,
                icon: playerService.isLoading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        playerService.isPlaying
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
                playerService.isRepeat ? Icons.repeat_one : Icons.repeat,
                color: playerService.isRepeat
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