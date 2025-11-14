import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户偏好服务
/// 管理用户的主题偏好、播放设置等
class UserPreferencesService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _autoPlayKey = 'auto_play';
  static const String _volumeKey = 'volume';
  static const String _qualityKey = 'audio_quality';

  late SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  bool _autoPlay = false;
  double _volume = 1.0;
  String _audioQuality = 'high';

  ThemeMode get themeMode => _themeMode;
  bool get autoPlay => _autoPlay;
  double get volume => _volume;
  String get audioQuality => _audioQuality;

  /// 初始化服务，从本地存储加载偏好设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  /// 设置自动播放
  Future<void> setAutoPlay(bool enabled) async {
    _autoPlay = enabled;
    await _prefs.setBool(_autoPlayKey, enabled);
    notifyListeners();
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_volumeKey, _volume);
    notifyListeners();
  }

  /// 设置音频质量
  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    await _prefs.setString(_qualityKey, quality);
    notifyListeners();
  }

  /// 切换主题模式
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> _loadPreferences() async {
    _themeMode = ThemeMode.values[_prefs.getInt(_themeModeKey) ?? ThemeMode.system.index];
    _autoPlay = _prefs.getBool(_autoPlayKey) ?? false;
    _volume = _prefs.getDouble(_volumeKey) ?? 1.0;
    _audioQuality = _prefs.getString(_qualityKey) ?? 'high';
  }

  /// 重置所有偏好设置
  Future<void> resetPreferences() async {
    await _prefs.clear();
    await _loadPreferences();
    notifyListeners();
  }
}