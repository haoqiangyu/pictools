import 'dart:convert';

/// 窗口类型枚举
enum WindowType {
  main,
  imageCompare,
  imageAdjust,
  imageEnhance,
  aiImage,
  backgroundRemoval,
  settings,
}

/// 窗口参数
class WindowArguments {
  final WindowType type;
  final Map<String, dynamic>? data;

  const WindowArguments({required this.type, this.data});

  /// 从 JSON 字符串解析
  factory WindowArguments.fromJson(String jsonStr) {
    if (jsonStr.isEmpty) {
      return const WindowArguments(type: WindowType.main);
    }
    try {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return WindowArguments(
        type: WindowType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => WindowType.main,
        ),
        data: json['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return const WindowArguments(type: WindowType.main);
    }
  }

  /// 转换为 JSON 字符串
  String toJson() {
    return jsonEncode({'type': type.name, if (data != null) 'data': data});
  }

  /// 获取窗口标题
  String get windowTitle {
    switch (type) {
      case WindowType.main:
        return 'Pictools';
      case WindowType.imageCompare:
        return 'Pictools - 图片对比';
      case WindowType.imageAdjust:
        return 'Pictools - 图片调整';
      case WindowType.imageEnhance:
        return 'Pictools - 亮度增强';
      case WindowType.aiImage:
        return 'Pictools - AI 图片修改';
      case WindowType.backgroundRemoval:
        return 'Pictools - 主体抠图';
      case WindowType.settings:
        return 'Pictools - 设置';
    }
  }

  /// 获取路由名称
  String get routeName {
    switch (type) {
      case WindowType.main:
        return '/';
      case WindowType.imageCompare:
        return '/image-compare';
      case WindowType.imageAdjust:
        return '/image-adjust';
      case WindowType.imageEnhance:
        return '/image-enhance';
      case WindowType.aiImage:
        return '/ai-image';
      case WindowType.backgroundRemoval:
        return '/background-removal';
      case WindowType.settings:
        return '/settings';
    }
  }

  /// 从路由名称获取窗口类型
  static WindowType fromRouteName(String routeName) {
    switch (routeName) {
      case '/image-compare':
        return WindowType.imageCompare;
      case '/image-adjust':
        return WindowType.imageAdjust;
      case '/image-enhance':
        return WindowType.imageEnhance;
      case '/ai-image':
        return WindowType.aiImage;
      case '/background-removal':
        return WindowType.backgroundRemoval;
      case '/settings':
        return WindowType.settings;
      default:
        return WindowType.main;
    }
  }
}
