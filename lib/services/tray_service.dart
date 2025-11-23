import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Service to manage system tray functionality
/// Provides tray icon, menu, and click event handling
class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;

  /// Initialize the system tray icon and menu
  Future<void> initialize() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    try {
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/tray_icon.ico'
            : 'assets/images/tray_icon.png',
      );

      // Set up tray menu
      Menu menu = Menu(
        items: [
          MenuItem(key: 'show_hide', label: '显示/隐藏'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      );

      await trayManager.setContextMenu(menu);
      await trayManager.setToolTip('音乐播放器');

      trayManager.addListener(this);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize tray: $e');
    }
  }

  /// Clean up tray resources
  Future<void> dispose() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
    }
  }

  @override
  void onTrayIconMouseDown() {
    // On single click, toggle window visibility
    _toggleWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Right click shows context menu (handled by tray_manager automatically)
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_hide':
        _toggleWindow();
        break;
      case 'exit':
        _exitApp();
        break;
    }
  }

  /// Toggle window visibility
  Future<void> _toggleWindow() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  /// Exit the application completely
  Future<void> _exitApp() async {
    await dispose();
    await windowManager.destroy();
    exit(0);
  }

  /// Show the window from tray
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// Hide the window to tray
  Future<void> hideWindow() async {
    await windowManager.hide();
  }
}
