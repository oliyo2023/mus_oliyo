import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// 音乐缓存服务，负责音频文件的下载和本地缓存管理
class MusicCacheService extends ChangeNotifier {
  static const String _cacheDirName = 'music_cache';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int _maxCacheFiles = 100; // 最多缓存100个文件

  Directory? _cacheDirectory;
  final Map<String, CacheInfo> _cacheInfo = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Map<String, CacheInfo> get cacheInfo => Map.unmodifiable(_cacheInfo);

  /// 初始化缓存服务
  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDirName');
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      // 加载缓存信息
      await _loadCacheInfo();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('初始化缓存服务失败: $e');
    }
  }

  /// 加载缓存信息
  Future<void> _loadCacheInfo() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      
      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileName = entity.uri.pathSegments.last;
          
          // 从文件名解析歌曲ID
          final songId = _extractSongIdFromFileName(fileName);
          if (songId != null) {
            _cacheInfo[songId] = CacheInfo(
              songId: songId,
              filePath: entity.path,
              fileSize: stat.size,
              createdAt: stat.changed,
              accessedAt: stat.accessed,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('加载缓存信息失败: $e');
    }
  }

  /// 从文件名提取歌曲ID
  String? _extractSongIdFromFileName(String fileName) {
    // 文件名格式: {song_id}.mp3
    if (fileName.endsWith('.mp3')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return null;
  }

  /// 生成缓存文件名
  String _getCacheFileName(String songId) {
    return '$songId.mp3';
  }

  /// 获取歌曲的本地缓存路径
  String? getCachedFilePath(String songId) {
    final info = _cacheInfo[songId];
    if (info != null && File(info.filePath).existsSync()) {
      // 更新访问时间
      _updateAccessTime(songId);
      return info.filePath;
    }
    return null;
  }

  /// 检查歌曲是否已缓存
  bool isCached(String songId) {
    return getCachedFilePath(songId) != null;
  }

  /// 获取缓存大小
  int get totalCacheSize {
    return _cacheInfo.values.fold(0, (sum, info) => sum + info.fileSize);
  }

  /// 获取缓存文件数量
  int get cacheFileCount => _cacheInfo.length;

  /// 下载并缓存音频文件
  Future<String?> downloadAndCache(Song song) async {
    if (!_isInitialized) {
      debugPrint('缓存服务未初始化');
      return null;
    }

    // 检查是否已缓存
    final cachedPath = getCachedFilePath(song.id);
    if (cachedPath != null) {
      debugPrint('歌曲已缓存: ${song.title}');
      return cachedPath;
    }

    try {
      // 检查网络连接
      // TODO: 添加网络连接检查

      // 检查缓存空间
      await _ensureCacheSpace();

      // 下载文件
      final response = await http.get(Uri.parse(song.url));
      
      if (response.statusCode == 200) {
        final fileName = _getCacheFileName(song.id);
        final filePath = '${_cacheDirectory!.path}/$fileName';
        final file = File(filePath);
        
        // 保存文件
        await file.writeAsBytes(response.bodyBytes);
        
        // 更新缓存信息
        final stat = await file.stat();
        _cacheInfo[song.id] = CacheInfo(
          songId: song.id,
          filePath: filePath,
          fileSize: stat.size,
          createdAt: stat.changed,
          accessedAt: stat.accessed,
        );
        
        notifyListeners();
        debugPrint('歌曲缓存成功: ${song.title}');
        return filePath;
      } else {
        debugPrint('下载失败: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('下载和缓存失败: $e');
      return null;
    }
  }

  /// 确保有足够的缓存空间
  Future<void> _ensureCacheSpace() async {
    // 检查总大小
    while (totalCacheSize > _maxCacheSize && _cacheInfo.isNotEmpty) {
      await _removeOldestCache();
    }

    // 检查文件数量
    while (cacheFileCount > _maxCacheFiles && _cacheInfo.isNotEmpty) {
      await _removeOldestCache();
    }
  }

  /// 删除最旧的缓存
  Future<void> _removeOldestCache() async {
    if (_cacheInfo.isEmpty) return;

    // 找到最久未访问的文件
    CacheInfo? oldestInfo;
    for (var info in _cacheInfo.values) {
      if (oldestInfo == null || info.accessedAt.isBefore(oldestInfo.accessedAt)) {
        oldestInfo = info;
      }
    }

    if (oldestInfo != null) {
      await removeCache(oldestInfo.songId);
    }
  }

  /// 删除缓存
  Future<void> removeCache(String songId) async {
    final info = _cacheInfo[songId];
    if (info != null) {
      try {
        final file = File(info.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _cacheInfo.remove(songId);
        notifyListeners();
        debugPrint('删除缓存: $songId');
      } catch (e) {
        debugPrint('删除缓存失败: $e');
      }
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (var entity in files) {
        if (entity is File) {
          await entity.delete();
        }
      }
      _cacheInfo.clear();
      notifyListeners();
      debugPrint('清空所有缓存');
    } catch (e) {
      debugPrint('清空缓存失败: $e');
    }
  }

  /// 更新访问时间
  void _updateAccessTime(String songId) {
    final info = _cacheInfo[songId];
    if (info != null) {
      info.accessedAt = DateTime.now();
    }
  }

  /// 获取缓存统计信息
  CacheStats get stats {
    return CacheStats(
      totalSize: totalCacheSize,
      fileCount: cacheFileCount,
      maxSize: _maxCacheSize,
      maxFiles: _maxCacheFiles,
    );
  }
}

/// 缓存信息
class CacheInfo {
  final String songId;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  DateTime accessedAt;

  CacheInfo({
    required this.songId,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.accessedAt,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Duration get age => DateTime.now().difference(createdAt);
}

/// 缓存统计信息
class CacheStats {
  final int totalSize;
  final int fileCount;
  final int maxSize;
  final int maxFiles;

  const CacheStats({
    required this.totalSize,
    required this.fileCount,
    required this.maxSize,
    required this.maxFiles,
  });

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  double get sizeUsagePercent => (totalSize / maxSize) * 100;
  double get fileUsagePercent => (fileCount / maxFiles) * 100;
}