import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../../services/music_api_service.dart';
import '../../widgets/search_history_chips.dart';
import '../../widgets/popular_searches.dart';

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
        SearchHistoryChips(
          onChipPressed: (term) {
            _searchController.text = term;
            _performSearch(term);
          },
        ),
        const SizedBox(height: 24),
        const Text(
          '热门搜索',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // 热门搜索组件
        PopularSearches(
          onSearchPressed: (term) {
            _searchController.text = term;
            _performSearch(term);
          },
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }
}