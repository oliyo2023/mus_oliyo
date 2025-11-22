import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/audio_player_service.dart';
import '../services/music_api_service.dart';

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
            child: IndexedStack(index: _currentIndex, children: _pages),
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

  Widget _buildDailyRecommendSection() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '每日推荐',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/daily-recommend');
                },
                child: const Text('查看更多'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Consumer<MusicApiService>(
              builder: (context, apiService, child) {
                return FutureBuilder<List<Song>>(
                  future: apiService.getDailyRecommend(limit: 6),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('加载每日推荐失败: ${snapshot.error}'));
                    }

                    final songs = snapshot.data ?? [];
                    if (songs.isEmpty) {
                      return const Center(child: Text('暂无每日推荐'));
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: songs
                          .map((song) => _buildDailyRecommendCard(song))
                          .toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendCard(Song song) {
    return Builder(
      builder: (context) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withValues(alpha: 0.8),
              Colors.purple.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _playSong(context, song),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playSong(BuildContext context, Song song) async {
    final audioPlayerService = context.read<AudioPlayerService>();
    final apiService = context.read<MusicApiService>();

    // 如果歌曲已有URL，直接播放
    if (song.url.isNotEmpty &&
        song.url !=
            'https://example.com/music/daily${song.id.replaceAll('daily', '')}.mp3') {
      audioPlayerService.setPlaylist([song]);
      audioPlayerService.playSong(song);
      return;
    }

    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 异步获取URL
      final url = await apiService.getSongUrl(song.hash128 ?? song.id);

      // 关闭加载提示
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (url != null && url.isNotEmpty) {
        final updatedSong = song.copyWith(url: url);
        audioPlayerService.setPlaylist([updatedSong]);
        audioPlayerService.playSong(updatedSong);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取播放地址，可能是VIP歌曲或版权限制')),
          );
        }
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

  Widget _buildNewSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '新歌速递',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // TODO: 导航到新歌速递页面
              },
              child: const Text('查看更多'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildNewSongCard('最新热门', Icons.trending_up, Colors.red),
              _buildNewSongCard('华语新歌', Icons.language, Colors.blue),
              _buildNewSongCard('欧美新歌', Icons.music_note, Colors.green),
              _buildNewSongCard('日韩新歌', Icons.queue_music, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewSongCard(String title, IconData icon, Color color) {
    return Builder(
      builder: (context) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pushNamed('/new-songs');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyRecommendSection(),
            const SizedBox(height: 32),
            _buildNewSongsSection(),
            const SizedBox(height: 32),
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String? _error;
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _currentQuery = query.trim();
    });

    try {
      final apiService = context.read<MusicApiService>();
      final results = await apiService.searchMusic(query, limit: 50);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索歌曲、艺术家、专辑...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _error = null;
                            _currentQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _currentQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDefaultContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('搜索失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_currentQuery),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '没有找到 "$_currentQuery" 的结果',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _performSearch(_currentQuery),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final song = _searchResults[index];
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
                onPressed: () => _playSong(song),
              ),
              onTap: () => _playSong(song),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultContent() {
    return ListView(
      children: [
        const Text(
          '最近搜索',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // 搜索历史组件
        const SearchHistoryChips(),
        const SizedBox(height: 24),
        const Text(
          '热门搜索',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // 热门搜索组件
        const PopularSearches(),
      ],
    );
  }

  Future<void> _playSong(Song song) async {
    final audioPlayerService = context.read<AudioPlayerService>();
    final apiService = context.read<MusicApiService>();

    // 如果歌曲已有URL，直接播放
    if (song.url.isNotEmpty &&
        song.url !=
            'https://example.com/music/daily${song.id.replaceAll('daily', '')}.mp3') {
      audioPlayerService.setPlaylist([song]);
      audioPlayerService.playSong(song);
      return;
    }

    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 异步获取URL
      final url = await apiService.getSongUrl(song.hash128 ?? song.id);

      // 关闭加载提示
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (url != null && url.isNotEmpty) {
        final updatedSong = song.copyWith(url: url);
        audioPlayerService.setPlaylist([updatedSong]);
        audioPlayerService.playSong(updatedSong);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取播放地址，可能是VIP歌曲或版权限制')),
          );
        }
      }
    } catch (e) {
      // 关闭加载提示
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
      }
    }
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

class SearchHistoryChips extends StatelessWidget {
  const SearchHistoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['周杰伦', '林俊杰', '邓紫棋', '薛之谦', '李荣浩']
          .map(
            (term) => Chip(
              label: Text(term),
              onDeleted: () {},
              deleteIcon: const Icon(Icons.close, size: 16),
              onPressed: () {
                final searchPageState = context
                    .findAncestorStateOfType<_SearchPageState>();
                if (searchPageState != null) {
                  searchPageState._searchController.text = term;
                  searchPageState._performSearch(term);
                }
              },
            ),
          )
          .toList(),
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
      children: searches
          .map(
            (search) => ListTile(
              leading: Icon(
                search['hot'] == true
                    ? Icons.local_fire_department
                    : Icons.trending_up,
                color: search['hot'] == true ? Colors.red : Colors.grey,
              ),
              title: Text(search['term'] as String),
              trailing: search['hot'] == true
                  ? const Icon(Icons.trending_up)
                  : null,
              onTap: () {},
            ),
          )
          .toList(),
    );
  }
}

class PlaylistsList extends StatelessWidget {
  const PlaylistsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicApiService, bool>(
      selector: (context, service) => service.isAuthenticated,
      builder: (context, isAuthenticated, child) {
        if (!isAuthenticated) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('登录后可查看您的歌单', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return FutureBuilder<List<Playlist>>(
          future: context.read<MusicApiService>().getPlaylists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('加载歌单失败: ${snapshot.error}'));
            }

            final playlists = snapshot.data ?? [];
            if (playlists.isEmpty) {
              return const Center(child: Text('暂无歌单'));
            }

            return Column(
              children: playlists
                  .map(
                    (playlist) => PlaylistCard(
                      title: playlist.name,
                      count: playlist.songs.length,
                      onTap: () {
                        // TODO: 实现歌单详情页面
                      },
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

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
