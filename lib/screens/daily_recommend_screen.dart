import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../controllers/daily_recommend_controller.dart';

class DailyRecommendScreen extends StatelessWidget {
  const DailyRecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DailyRecommendController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日推荐'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDailyRecommend(),
          ),
        ],
      ),
      body: Obx(() => _buildBody(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, DailyRecommendController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error.value != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                controller.error.value!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadDailyRecommend(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (controller.songs.isEmpty) {
      return const Center(child: Text('暂无每日推荐数据'));
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.songs.length,
        itemBuilder: (context, index) {
          final song = controller.songs[index];
          return _buildSongItem(context, song, controller);
        },
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    Song song,
    DailyRecommendController controller,
  ) {
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
                      return const Icon(Icons.music_note, color: Colors.grey);
                    },
                  ),
                )
              : const Icon(Icons.music_note, color: Colors.grey),
        ),
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _playSong(context, song, controller),
        ),
        onTap: () => _playSong(context, song, controller),
      ),
    );
  }

  Future<void> _playSong(
    BuildContext context,
    Song song,
    DailyRecommendController controller,
  ) async {
    // 显示加载提示
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await controller.playSong(song);
      // 关闭加载提示
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    } catch (e) {
      // 关闭加载提示
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // 显示错误提示
      Get.snackbar(
        '播放失败',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
