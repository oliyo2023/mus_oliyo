import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

/// 播放历史服务
/// 管理用户的播放历史记录
class PlayHistoryService extends ChangeNotifier {
  static const String _historyKey = 'play_history';
  static const int _maxHistorySize = 100;

  late SharedPreferences _prefs;
  final List<Song> _playHistory = [];

  List<Song> get playHistory => List.unmodifiable(_playHistory);

  /// 初始化服务，从本地存储加载历史记录
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
  }

  /// 添加歌曲到播放历史
  Future<void> addToHistory(Song song) async {
    // 移除已存在的相同歌曲
    _playHistory.removeWhere((s) => s.id == song.id);

    // 添加到历史开头
    _playHistory.insert(0, song);

    // 限制历史记录数量
    if (_playHistory.length > _maxHistorySize) {
      _playHistory.removeRange(_maxHistorySize, _playHistory.length);
    }

    await _saveHistory();
    notifyListeners();
  }

  /// 从历史记录中移除歌曲
  Future<void> removeFromHistory(String songId) async {
    _playHistory.removeWhere((song) => song.id == songId);
    await _saveHistory();
    notifyListeners();
  }

  /// 清空播放历史
  Future<void> clearHistory() async {
    _playHistory.clear();
    await _prefs.remove(_historyKey);
    notifyListeners();
  }

  /// 获取最近播放的歌曲
  List<Song> getRecentSongs({int limit = 10}) {
    return _playHistory.take(limit).toList();
  }

  /// 检查歌曲是否在历史记录中
  bool isInHistory(String songId) {
    return _playHistory.any((song) => song.id == songId);
  }

  /// 获取播放历史的统计信息
  Map<String, dynamic> getHistoryStats() {
    if (_playHistory.isEmpty) {
      return {
        'totalSongs': 0,
        'uniqueArtists': 0,
        'uniqueAlbums': 0,
      };
    }

    final artists = _playHistory.map((song) => song.artist).toSet();
    final albums = _playHistory.map((song) => song.album).toSet();

    return {
      'totalSongs': _playHistory.length,
      'uniqueArtists': artists.length,
      'uniqueAlbums': albums.length,
    };
  }

  Future<void> _loadHistory() async {
    final historyJson = _prefs.getStringList(_historyKey) ?? [];
    _playHistory.clear();

    for (final jsonStr in historyJson) {
      try {
        final songMap = Map<String, dynamic>.from(
          jsonStr.split('|').fold<Map<String, dynamic>>({}, (map, pair) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              map[parts[0]] = parts[1];
            }
            return map;
          }),
        );

        final song = Song.fromJson(songMap);
        _playHistory.add(song);
      } catch (e) {
        debugPrint('加载历史记录失败: $e');
      }
    }
  }

  Future<void> _saveHistory() async {
    final historyJson = _playHistory.map((song) {
      final json = song.toJson();
      return json.entries.map((e) => '${e.key}:${e.value}').join('|');
    }).toList();

    await _prefs.setStringList(_historyKey, historyJson);
  }

  @override
  void dispose() {
    // 不需要清理 SharedPreferences
    super.dispose();
  }
}