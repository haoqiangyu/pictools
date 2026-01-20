import 'dart:ui';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'window_arguments.dart';

/// 窗口管理服务
class WindowService {
  WindowService._();

  static final instance = WindowService._();

  /// 当前窗口控制器
  WindowController? _currentController;
  WindowController? get currentController => _currentController;

  /// 当前窗口参数
  WindowArguments? _currentArguments;
  WindowArguments? get currentArguments => _currentArguments;

  /// 是否是主窗口
  bool get isMainWindow => _currentArguments?.type == WindowType.main;

  /// 最小窗口尺寸
  static const Size minWindowSize = Size(800, 600);

  /// 初始化窗口服务
  /// 返回当前窗口参数，主窗口需要自行调用 windowManager 初始化
  Future<WindowArguments> init() async {
    _currentController = await WindowController.fromCurrentEngine();
    _currentArguments = WindowArguments.fromJson(
      _currentController?.arguments ?? '',
    );

    // 只有子窗口需要在这里初始化 window_manager
    // 主窗口在 main.dart 中统一初始化以避免重复
    if (!isMainWindow) {
      await windowManager.ensureInitialized();

      await windowManager.setTitle(
        _currentArguments?.windowTitle ?? 'Pictools',
      );
      await windowManager.setMinimumSize(minWindowSize);

      // 固定窗口尺寸
      Size initialSize = const Size(1000, 800);
      if (_currentArguments?.type == WindowType.imageCompare) {
        initialSize = const Size(1200, 800);
      }

      // 设置背景色为深色，避免白色闪烁
      await windowManager.setBackgroundColor(const Color(0xFF1E1E1E));

      WindowOptions windowOptions = WindowOptions(
        size: initialSize,
        center: true,
        backgroundColor: const Color(0xFF1E1E1E),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    return _currentArguments ?? const WindowArguments(type: WindowType.main);
  }

  /// 在新窗口中打开工具
  Future<WindowController?> openInNewWindow(
    WindowType type, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final args = WindowArguments(type: type, data: data);

      // 使用 hiddenAtLaunch: true 避免黑屏闪烁
      final controller = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: args.toJson()),
      );

      return controller;
    } catch (e) {
      debugPrint('Failed to open new window: $e');
      return null;
    }
  }

  /// 分离当前页面到新窗口
  /// 返回 true 表示成功创建了新窗口，调用者应返回首页
  Future<bool> detachToNewWindow(
    WindowType type, {
    Map<String, dynamic>? data,
  }) async {
    if (!isMainWindow) {
      // 如果已经是子窗口，不需要分离
      return false;
    }

    final controller = await openInNewWindow(type, data: data);
    return controller != null;
  }

  /// 关闭当前窗口
  Future<void> closeCurrentWindow() async {
    if (!isMainWindow) {
      // 子窗口使用 window_manager 关闭
      await windowManager.close();
    }
  }

  /// 获取所有窗口
  Future<List<WindowController>> getAllWindows() async {
    return await WindowController.getAll();
  }
}
