import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

/// 音乐 API 服务，处理与酷狗音乐 API 的通信
class MusicApiService extends ChangeNotifier {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'https://cors-proxy.fringe.zone/https://mus.oliyo.com';
    }
    return 'https://mus.oliyo.com';
  }

  // 本地存储键
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  String? _authToken;
  String? _userId;
  late SharedPreferences _prefs;

  // 单例模式
  static final MusicApiService _instance = MusicApiService._internal();
  factory MusicApiService() => _instance;
  MusicApiService._internal();

  /// 获取认证令牌
  String? get authToken => _authToken;

  /// 获取用户ID
  String? get userId => _userId;

  /// 检查是否已认证
  bool get isAuthenticated => _authToken != null && _userId != null;

  /// 初始化服务，从本地存储加载认证信息
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAuthData();
  }

  /// 从本地存储加载认证数据
  Future<void> _loadAuthData() async {
    _authToken = _prefs.getString(_authTokenKey);
    _userId = _prefs.getString(_userIdKey);
    debugPrint(
      '从本地存储加载认证信息: token=${_authToken != null}, userId=${_userId != null}',
    );
    notifyListeners();
  }

  /// 保存认证数据到本地存储
  Future<void> _saveAuthData() async {
    if (_authToken != null) {
      await _prefs.setString(_authTokenKey, _authToken!);
    } else {
      await _prefs.remove(_authTokenKey);
    }

    if (_userId != null) {
      await _prefs.setString(_userIdKey, _userId!);
    } else {
      await _prefs.remove(_userIdKey);
    }
  }

  /// 发送验证码
  Future<Map<String, dynamic>> sendCaptcha(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/captcha/sent?mobile=$phone'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          return {'success': true, 'message': '验证码发送成功'};
        } else {
          throw Exception(data['message'] ?? '发送验证码失败');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('发送验证码失败: $e');
      rethrow;
    }
  }

  /// 手机号登录
  Future<Map<String, dynamic>> loginWithPhone(
    String phone,
    String captcha,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/login/cellphone?mobile=$phone&code=$captcha'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final userData = data['data'];
          _authToken = userData['token'] ?? '';
          _userId = userData['userid']?.toString() ?? '';
          await _saveAuthData(); // 保存到本地存储
          notifyListeners(); // 通知UI更新登录状态
          debugPrint('手机号登录成功，已保存认证信息到本地存储');
          return {'success': true, 'token': _authToken, 'user': userData};
        } else {
          throw Exception(data['message'] ?? '登录失败');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('手机号登录失败: $e');
      rethrow;
    }
  }

  /// 用户登录（保留原有方法用于兼容）
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _authToken = data['token'];
          _userId = data['user']['id'];
          await _saveAuthData(); // 保存到本地存储
          debugPrint('邮箱登录成功，已保存认证信息到本地存储');
          return {'success': true, 'token': _authToken, 'user': data['user']};
        } else {
          throw Exception(data['message'] ?? '登录失败');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      rethrow;
    }
  }

  /// 使用演示账户登录（用于快速测试）
  Future<Map<String, dynamic>> loginWithDemo() async {
    return await login('demo@example.com', 'password123');
  }

  /// 退出登录
  Future<void> logout() async {
    _authToken = null;
    _userId = null;
    await _saveAuthData(); // 清除本地存储的认证信息
    debugPrint('已退出登录并清除本地存储的认证信息');
    notifyListeners(); // 通知UI更新登录状态
  }

  /// 获取请求头
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// 搜索音乐
  Future<List<Song>> searchMusic(String query, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?keywords=${Uri.encodeComponent(query)}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 0 && data['data'] is List) {
          final songs = data['data'] as List;
          return songs
              .map(
                (songJson) =>
                    Song.fromKugouJson(songJson as Map<String, dynamic>),
              )
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('搜索失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('搜索音乐失败: $e');
      rethrow;
    }
  }

  /// 获取每日推荐歌曲
  Future<List<Song>> getDailyRecommend({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/everyday/recommend'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('每日推荐API响应: $data');
        if (data['status'] == 1 && data['data'] is List) {
          final songs = data['data'] as List;
          return songs
              .take(limit)
              .map(
                (songJson) =>
                    Song.fromKugouJson(songJson as Map<String, dynamic>),
              )
              .toList();
        } else {
          debugPrint(
            '每日推荐API返回状态异常: ${data['status']}, data类型: ${data['data']?.runtimeType}, data内容: ${data['data']}',
          );
          // 返回模拟数据作为后备
          return _getMockDailyRecommend();
        }
      } else {
        debugPrint('每日推荐API请求失败: HTTP ${response.statusCode}');
        // 返回模拟数据作为后备
        return _getMockDailyRecommend();
      }
    } catch (e) {
      debugPrint('获取每日推荐失败: $e');
      // 返回模拟数据作为后备
      return _getMockDailyRecommend();
    }
  }

  /// 获取热门歌曲（新歌速递）
  Future<List<Song>> getTrendingTracks({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/top/song'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] is List) {
          final songs = data['data'] as List;
          return songs
              .take(limit)
              .map(
                (songJson) =>
                    Song.fromKugouJson(songJson as Map<String, dynamic>),
              )
              .toList();
        } else {
          // 返回模拟数据作为后备
          return _getMockTrendingSongs();
        }
      } else {
        // 返回模拟数据作为后备
        return _getMockTrendingSongs();
      }
    } catch (e) {
      debugPrint('获取热门歌曲失败: $e');
      // 返回模拟数据作为后备
      return _getMockTrendingSongs();
    }
  }

  /// 获取歌曲详情
  Future<Song?> getTrack(String trackId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/song/info?hash=$trackId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] is Map) {
          return Song.fromKugouJson(data['data'] as Map<String, dynamic>);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('获取歌曲详情失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取歌曲详情失败: $e');
      return null;
    }
  }

  /// 获取歌曲播放URL
  Future<String?> getSongUrl(String hash, {String quality = '128'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/song/url?hash=$hash&format=json'),
        headers: _getHeaders(),
      );

      debugPrint('getSongUrl response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);

        if (jsonResponse is! Map<String, dynamic>) {
          debugPrint('getSongUrl: response is not a Map');
          return null;
        }

        final data = jsonResponse;

        // 检查状态码
        if (data['status'] != 1) {
          debugPrint(
            'getSongUrl failed: status=${data['status']}, fail_process=${data['fail_process']}',
          );
          // 如果是 status 2 (通常是付费或VIP)，可以在这里抛出特定异常或返回 null
          return null;
        }

        String? audioUrl;

        // 策略1: data['url'] 是列表
        if (data['url'] is List && data['url'].isNotEmpty) {
          final firstUrl = data['url'][0];
          // 情况A: 列表元素是 Map (原有逻辑)
          if (firstUrl is Map && firstUrl.containsKey('url')) {
            audioUrl = firstUrl['url'] as String?;
          }
          // 情况B: 列表元素是 String (新发现的格式)
          else if (firstUrl is String) {
            audioUrl = firstUrl;
          }
        }

        // 策略2: data['data']['play_url'] (常见酷狗API格式)
        if (audioUrl == null &&
            data['data'] is Map &&
            data['data']['play_url'] != null) {
          audioUrl = data['data']['play_url'] as String?;
        }

        // 策略3: data['play_url'] (直接字段)
        if (audioUrl == null && data['play_url'] != null) {
          audioUrl = data['play_url'] as String?;
        }

        // 验证获取到的URL
        if (audioUrl != null && audioUrl.isNotEmpty) {
          // 确保URL是有效的HTTP/HTTPS URL
          if (!audioUrl.startsWith('http://') &&
              !audioUrl.startsWith('https://')) {
            debugPrint('getSongUrl: Invalid URL format: $audioUrl');
            return null;
          }

          // 验证URL是否可以解析
          final uri = Uri.tryParse(audioUrl);
          if (uri == null) {
            debugPrint('getSongUrl: Cannot parse URL: $audioUrl');
            return null;
          }

          debugPrint('getSongUrl: Successfully got URL: $audioUrl');
          return audioUrl;
        }

        debugPrint('getSongUrl: No valid URL found in response');
        return null;
      } else {
        debugPrint('getSongUrl: HTTP error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取播放URL失败: $e');
      return null;
    }
  }

  /// 获取用户歌单列表
  Future<List<Playlist>> getPlaylists() async {
    if (!isAuthenticated) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/playlist?userid=$_userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 && data['data'] is List) {
          final playlists = data['data'] as List;
          return playlists
              .map((playlistJson) => Playlist.fromJson(playlistJson))
              .toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('获取歌单列表失败: $e');
      return [];
    }
  }

  /// 获取歌单详情
  Future<Playlist?> getPlaylist(String playlistId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/playlist/detail?global_collection_id=$playlistId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          return Playlist.fromJson(data['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('获取歌单详情失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取歌单详情失败: $e');
      return null;
    }
  }

  /// 创建新歌单
  Future<Playlist?> createPlaylist(
    String name, {
    String? description,
    String? coverArt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/playlists'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'coverArt': coverArt,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Playlist.fromJson(data);
      } else {
        throw Exception('创建歌单失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('创建歌单失败: $e');
      return null;
    }
  }

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('健康检查失败: $e');
      return false;
    }
  }

  /// 获取模拟的每日推荐数据（作为后备）
  List<Song> _getMockDailyRecommend() {
    return [
      Song(
        id: 'daily1',
        title: '夜曲',
        artist: '周杰伦',
        album: '十一月的萧邦',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily1.mp3',
        duration: 229,
      ),
      Song(
        id: 'daily2',
        title: '稻香',
        artist: '周杰伦',
        album: '魔杰座',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily2.mp3',
        duration: 223,
      ),
      Song(
        id: 'daily3',
        title: '七里香',
        artist: '周杰伦',
        album: '七里香',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily3.mp3',
        duration: 295,
      ),
      Song(
        id: 'daily4',
        title: '青花瓷',
        artist: '周杰伦',
        album: '我很忙',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily4.mp3',
        duration: 154,
      ),
      Song(
        id: 'daily5',
        title: '听妈妈的话',
        artist: '周杰伦',
        album: '尚雯婕同名专辑',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily5.mp3',
        duration: 265,
      ),
      Song(
        id: 'daily6',
        title: '本草纲目',
        artist: '周杰伦',
        album: '本草纲目',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/daily6.mp3',
        duration: 215,
      ),
    ];
  }

  /// 获取模拟的热门歌曲数据（作为后备）
  List<Song> _getMockTrendingSongs() {
    return [
      Song(
        id: '1',
        title: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song1.mp3',
        duration: 269,
      ),
      Song(
        id: '2',
        title: '起风了',
        artist: '买辣椒也用券',
        album: '起风了',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song2.mp3',
        duration: 325,
      ),
      Song(
        id: '3',
        title: '孤勇者',
        artist: '陈奕迅',
        album: '孤勇者',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song3.mp3',
        duration: 268,
      ),
      Song(
        id: '4',
        title: '漠河舞厅',
        artist: '柳爽',
        album: '漠河舞厅',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song4.mp3',
        duration: 332,
      ),
      Song(
        id: '5',
        title: '花海',
        artist: '周杰伦',
        album: '魔杰座',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song5.mp3',
        duration: 266,
      ),
      Song(
        id: '6',
        title: '错位时空',
        artist: '艾辰',
        album: '错位时空',
        coverArt: 'https://via.placeholder.com/200',
        url: 'https://example.com/music/song6.mp3',
        duration: 226,
      ),
    ];
  }
}
