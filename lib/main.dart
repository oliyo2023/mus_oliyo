import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/new_songs_screen.dart';
import 'screens/daily_recommend_screen.dart';
import 'controllers/daily_recommend_controller.dart';
import 'services/audio_player_service.dart';
import 'services/music_api_service.dart';
import 'services/play_history_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tray_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Hide native title bar
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Initialize system tray
    await TrayService().initialize();

    // Prevent window from closing, hide to tray instead
    await windowManager.setPreventClose(true);
  }

  // 初始化服务
  final playHistoryService = PlayHistoryService();
  final userPreferencesService = UserPreferencesService();
  final audioPlayerService = AudioPlayerService();
  final musicApiService = MusicApiService();

  await Future.wait([
    playHistoryService.init(),
    userPreferencesService.init(),
    musicApiService.init(),
  ]);

  // 连接服务
  audioPlayerService.setHistoryService(playHistoryService);

  // 注册 GetX 依赖
  Get.put(musicApiService);
  Get.put(audioPlayerService);
  Get.lazyPut(
    () => DailyRecommendController(
      Get.find<MusicApiService>(),
      Get.find<AudioPlayerService>(),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: audioPlayerService),
        ChangeNotifierProvider.value(value: playHistoryService),
        ChangeNotifierProvider.value(value: userPreferencesService),
        ChangeNotifierProvider.value(value: musicApiService),
      ],
      child: const MusicApp(),
    ),
  );
}

class MusicApp extends StatefulWidget {
  const MusicApp({super.key});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Hide to tray instead of closing
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserPreferencesService, ThemeMode>(
      selector: (context, service) => service.themeMode,
      builder: (context, themeMode, child) {
        return GetMaterialApp(
          title: '音乐播放器',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const HomeScreen(), // 默认显示首页
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/new-songs': (context) => const NewSongsScreen(),
            '/daily-recommend': (context) => const DailyRecommendScreen(),
          },
        );
      },
    );
  }
}
