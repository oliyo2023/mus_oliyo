import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controllers/new_songs_controller.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../services/audio_player_service.dart';

class NewSongsScreen extends StatelessWidget {
  const NewSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller with dependencies
    final controller = Get.put(
      NewSongsController(
        context.read<MusicApiService>(),
        context.read<AudioPlayerService>(),
      ),
    );

    return _NewSongsView(controller: controller);
  }
}

class _NewSongsView extends StatelessWidget {
  final NewSongsController controller;

  const _NewSongsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新歌速递'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Obx(() => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.error.value != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              controller.error.value!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.forceRefresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (controller.songs.isEmpty) {
      // 如果正在加载，显示友好提示；否则显示无数据
      return Center(
        child: Text(
          controller.isLoading.value ? '加载中...' : '暂无新歌数据',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.forceRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.songs.length,
        itemBuilder: (context, index) {
          final song = controller.songs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
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
                onPressed: () => _playSong(song, context),
              ),
              onTap: () => _playSong(song, context),
            ),
          );
        },
      ),
    );
  }

  Future<void> _playSong(Song song, BuildContext context) async {
    try {
      // 如果歌曲已有URL，直接播放
      if (song.url.isNotEmpty) {
        await controller.playSong(song);
        return;
      }

      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await controller.playSong(song);

      // 关闭加载提示
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      // 关闭加载提示
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
      }
    }
  }
}
