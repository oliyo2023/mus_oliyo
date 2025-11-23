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
    debugPrint('Tray icon left-clicked');
    // On single click, toggle window visibility
    _toggleWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('Tray icon right-clicked');
    // Right click shows context menu (handled by tray_manager automatically)
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    // Debug: print all menu item properties
    debugPrint('=== Menu Item Clicked ===');
    debugPrint('  key: ${menuItem.key}');
    debugPrint('  label: ${menuItem.label}');
    debugPrint('========================');

    // Match by both key and label for compatibility
    final itemKey = menuItem.key ?? '';
    final itemLabel = menuItem.label ?? '';

    // Check key first, then fall back to label matching
    if (itemKey == 'show_hide' ||
        itemLabel == '显示/隐藏' ||
        itemLabel.contains('显示')) {
      debugPrint('Action: Toggle window');
      _toggleWindow();
    } else if (itemKey == 'exit' ||
        itemLabel == '退出' ||
        itemLabel.contains('退出')) {
      debugPrint('Action: Exit application');
      _exitApp();
    } else {
      debugPrint(
        'Warning: Unknown menu item - key: "$itemKey", label: "$itemLabel"',
      );
    }
  }

  /// Toggle window visibility
  Future<void> _toggleWindow() async {
    try {
      debugPrint('Toggling window visibility...');
      bool isVisible = await windowManager.isVisible();
      debugPrint('Window is currently visible: $isVisible');

      if (isVisible) {
        debugPrint('Hiding window...');
        await windowManager.hide();
      } else {
        debugPrint('Showing window...');
        await windowManager.show();
        await windowManager.focus();
      }
      debugPrint('Window toggle complete');
    } catch (e) {
      debugPrint('Error toggling window: $e');
    }
  }

  /// Exit the application completely
  Future<void> _exitApp() async {
    try {
      debugPrint('Exiting application...');
      await dispose();
      await windowManager.destroy();
      exit(0);
    } catch (e) {
      debugPrint('Error exiting app: $e');
      // Force exit if cleanup fails
      exit(1);
    }
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
