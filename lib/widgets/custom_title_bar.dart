import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom title bar widget for desktop platforms (Linux, Windows, macOS)
/// Provides window controls (minimize, maximize, close) and draggable area
class CustomTitleBar extends StatefulWidget {
  final String title;
  final Color? backgroundColor;

  const CustomTitleBar({super.key, this.title = '音乐播放器', this.backgroundColor});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    // Only use window manager on desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    // Only use window manager on desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  Future<void> _checkMaximized() async {
    bool isMaximized = await windowManager.isMaximized();
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show custom title bar on desktop platforms
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5));

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Draggable area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Window control buttons
          _WindowButton(
            icon: Icons.minimize,
            onPressed: () {
              windowManager.minimize();
            },
            tooltip: '最小化',
          ),
          _WindowButton(
            icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            tooltip: _isMaximized ? '还原' : '最大化',
          ),
          _WindowButton(
            icon: Icons.close,
            onPressed: () {
              windowManager.close();
            },
            tooltip: '最小化到托盘',
            isClose: true,
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color hoverColor;
    if (widget.isClose) {
      hoverColor = Colors.red;
    } else {
      hoverColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.05);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            hoverColor: hoverColor,
            child: Container(
              width: 46,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHovered ? hoverColor : Colors.transparent,
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: _isHovered && widget.isClose
                    ? Colors.white
                    : theme.iconTheme.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
