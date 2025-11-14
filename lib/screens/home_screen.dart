import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../models/song.dart';
import '../services/user_preferences_service.dart';
import '../widgets/player_bar.dart';
import '../widgets/sections/recent_section.dart';
import '../widgets/sections/popular_section.dart';
import '../widgets/sections/playlist_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const LibraryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          const PlayerBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: '音乐库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RecentSection(),
            const SizedBox(height: 32),
            const PopularSection(),
            const SizedBox(height: 32),
            const PlaylistSection(),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '搜索',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: '搜索歌曲、艺术家、专辑...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    '最近搜索',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 搜索历史组件
                  const SearchHistoryChips(),
                  const SizedBox(height: 24),
                  const Text(
                    '热门搜索',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 热门搜索组件
                  const PopularSearches(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '我的',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // 用户头像和信息
            UserCard(),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('设置'),
                    onTap: () {},
                  ),
                  Selector<UserPreferencesService, ThemeMode>(
                    selector: (context, service) => service.themeMode,
                    builder: (context, themeMode, child) {
                      final preferencesService = context.read<UserPreferencesService>();
                      final isDark = themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system &&
                           MediaQuery.of(context).platformBrightness == Brightness.dark);

                      return ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('深色模式'),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (value) {
                            preferencesService.toggleTheme();
                          },
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('帮助'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchHistoryChips extends StatelessWidget {
  const SearchHistoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        '周杰伦', '林俊杰', '邓紫棋', '薛之谦', '李荣浩'
      ].map((term) => Chip(
        label: Text(term),
        onDeleted: () {},
        deleteIcon: const Icon(Icons.close, size: 16),
      )).toList(),
    );
  }
}

class PopularSearches extends StatelessWidget {
  const PopularSearches({super.key});

  @override
  Widget build(BuildContext context) {
    final searches = [
      {'term': '孤勇者', 'hot': true},
      {'term': '漠河舞厅', 'hot': false},
      {'term': '错位时空', 'hot': true},
      {'term': '白月光与朱砂痣', 'hot': false},
    ];

    return Column(
      children: searches.map((search) => ListTile(
        leading: Icon(
          search['hot'] == true ? Icons.local_fire_department : Icons.trending_up,
          color: search['hot'] == true ? Colors.red : Colors.grey,
        ),
        title: Text(search['term'] as String),
        trailing: search['hot'] == true ? const Icon(Icons.trending_up) : null,
        onTap: () {},
      )).toList(),
    );
  }
}

class PlaylistsList extends StatelessWidget {
  const PlaylistsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlaylistCard(title: '驾驶音乐', count: 42),
        PlaylistCard(title: '运动健身', count: 35),
        PlaylistCard(title: '深夜电台', count: 28),
      ],
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String title;
  final int count;

  const PlaylistCard({
    super.key,
    required this.title,
    required this.count,
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
        onTap: () {},
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '音乐爱好者',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'VIP会员',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}