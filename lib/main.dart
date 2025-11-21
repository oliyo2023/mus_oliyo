import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/new_songs_screen.dart';
import 'services/audio_player_service.dart';
import 'services/music_api_service.dart';
import 'services/play_history_service.dart';
import 'services/user_preferences_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<UserPreferencesService, ThemeMode>(
      selector: (context, service) => service.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
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
          },
        );
      },
    );
  }
}
