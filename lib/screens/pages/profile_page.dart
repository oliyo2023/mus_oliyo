import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildUserInfo(context),
                    const SizedBox(height: 24),
                    _buildActionTabs(context),
                    const SizedBox(height: 24),
                    _buildPlaylistHeader(context),
                  ],
                ),
              ),
            ),
            _buildPlaylistList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '听歌总时长',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: '42'),
                  TextSpan(text: '小时', style: TextStyle(fontSize: 14)),
                  TextSpan(text: ' 50'),
                  TextSpan(text: '分钟', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Consumer<MusicApiService>(
      builder: (context, apiService, child) {
        final user = apiService.isAuthenticated
            ? {'name': 'kiro', 'avatar': 'https://via.placeholder.com/150'}
            : null;

        return Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: NetworkImage(
                    user?['avatar'] ?? 'https://via.placeholder.com/150',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name and VIP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?['name'] ?? '未登录',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (apiService.isAuthenticated) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Gender and School
            if (apiService.isAuthenticated)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.male, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    '安道尔 北方工业大学',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('点击登录'),
              ),
            const SizedBox(height: 16),
            // Stats
            if (apiService.isAuthenticated)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem('33', '关注'),
                  const SizedBox(width: 24),
                  _buildStatItem('10', '粉丝'),
                  const SizedBox(width: 24),
                  _buildStatItem('0', '获赞'),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Row(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionTabs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTabItem(Icons.queue_music, '歌单', isSelected: true),
        _buildTabItem(Icons.download_outlined, '下载'),
        _buildTabItem(Icons.history, '历史播放'),
        _buildTabItem(Icons.play_circle_outline, '视频'),
        _buildTabItem(Icons.music_note_outlined, '音乐'),
      ],
    );
  }

  Widget _buildTabItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 2,
            color: Colors.white,
          ),
      ],
    );
  }

  Widget _buildPlaylistHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('创建的歌单', style: TextStyle(color: Colors.grey, fontSize: 14)),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.input, size: 16, color: Colors.grey),
              label: const Text('导入', style: TextStyle(color: Colors.grey)),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Colors.grey),
              label: const Text('创建', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaylistList(BuildContext context) {
    final playlists = [
      {
        'title': '我喜欢的音乐',
        'count': 8,
        'icon': Icons.favorite,
        'color': Colors.grey,
      },
      {
        'title': '抖音收藏的音乐',
        'count': 0,
        'icon': Icons.tiktok,
        'color': Colors.black,
      },
      {
        'title': '导入外部歌单',
        'count': null,
        'icon': Icons.input,
        'color': Colors.teal,
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final playlist = playlists[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: playlist['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  playlist['icon'] as IconData,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (playlist['count'] != null)
                      Text(
                        playlist['count'] == 0
                            ? '🔒 0首'
                            : '${playlist['count']}首',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }, childCount: playlists.length),
    );
  }
}