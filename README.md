# 音乐播放器 App

基于 Flutter 开发的现代化音乐播放器应用，界面设计参考了主流音乐APP如网易云音乐、QQ音乐等。

## 功能特性

### 🎵 核心功能
- 音乐播放控制（播放、暂停、上一首、下一首）
- 播放列表管理
- 随机播放和循环播放
- 进度控制和拖拽
- 歌词显示
- 音频服务集成

### 🎨 界面设计
- 现代化深色主题设计
- 渐变色彩和毛玻璃效果
- 流畅的页面转场动画
- 响应式布局设计
- 底部播放控制栏

### 📱 页面结构
- **首页**: 最近播放、热门推荐、歌单推荐
- **搜索**: 歌曲搜索、热门搜索、搜索历史
- **音乐库**: 收藏音乐、播放历史、本地音乐、自定义歌单
- **个人中心**: 用户信息、设置、主题切换

### 🎭 用户体验
- 直观的导航结构
- 流畅的手势操作
- 丰富的视觉反馈
- 可定制的播放模式

## 技术架构

### 状态管理
- Provider 状态管理
- 音频播放器服务
- 响应式UI更新

### 核心组件
- **AudioPlayerService**: 音频播放核心服务
- **Song**: 音乐数据模型
- **Playlist**: 歌单数据模型
- **PlayerControls**: 播放控制组件
- **SongCard**: 歌曲卡片组件

### 依赖包
```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  provider: ^6.1.2

  # 音频播放
  just_audio: ^0.9.41
  audio_session: ^0.1.21

  # UI组件
  font_awesome_flutter: ^10.7.0
  glassmorphism: ^3.0.0
  lottie: ^3.1.2

  # 网络和缓存
  http: ^1.2.2
  cached_network_image: ^3.3.1

  # 工具类
  path_provider: ^2.1.3
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   ├── song.dart               # 歌曲数据模型
│   └── playlist.dart           # 歌单数据模型
├── services/
│   └── audio_player_service.dart # 音频播放服务
├── screens/
│   ├── home_screen.dart         # 完整功能主屏幕
│   ├── home_screen_simple.dart  # 简化版主屏幕
│   └── player_screen.dart       # 播放器界面
├── widgets/
│   ├── player_bar.dart          # 底部播放栏
│   ├── player_controls.dart     # 播放控制组件
│   ├── song_card.dart           # 歌曲卡片
│   ├── lyrics_section.dart      # 歌词区域
│   ├── playlist_section.dart    # 播放列表
│   └── sections/
│       ├── recent_section.dart  # 最近播放
│       ├── popular_section.dart # 热门推荐
│       └── playlist_section.dart # 推荐歌单
└── theme/
    └── app_theme.dart           # 应用主题
```

## 快速开始

### 环境要求
- Flutter SDK >= 3.9.2
- Dart SDK >= 3.0.0
- Android / iOS 开发环境

### 安装和运行

1. 克隆项目
```bash
git clone <repository-url>
cd music.oliyo.com
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 开发模式

当前项目提供了两个版本：
- **home_screen.dart**: 完整功能版本（需要网络下载依赖）
- **home_screen_simple.dart**: 简化版本（无需额外依赖，可直接运行）

在开发过程中，可以根据需要切换 main.dart 中的导入。

## 界面预览

### 主界面
- 欢迎界面和用户问候
- 横向滚动的音乐推荐
- 网格布局的歌单推荐
- 底部导航栏切换

### 播放器界面
- 全屏专辑封面展示
- 歌曲信息和进度条
- 播放控制按钮组
- 歌词和播放列表标签页

### 搜索界面
- 搜索输入框
- 热门搜索标签
- 搜索历史记录

### 音乐库界面
- 分类音乐入口
- 个人歌单管理
- 本地音乐访问

## 开发计划

### 已完成 ✅
- [x] 项目基础架构搭建
- [x] 核心数据模型设计
- [x] 音频播放服务实现
- [x] 主界面和导航结构
- [x] 播放器界面和控制
- [x] 歌单和搜索功能
- [x] 主题和UI组件

### 待实现 🚧
- [ ] 真实音频播放功能
- [ ] 在线歌词获取
- [ ] 用户登录系统
- [ ] 云端歌单同步
- [ ] 音乐推荐算法
- [ ] 社交分享功能

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 许可证

本项目采用 MIT 许可证。

---

**注意**: 这是一个演示项目，主要用于展示 Flutter 音乐播放器的开发思路和界面设计。在实际使用中，需要集成真实的音乐服务和API。
