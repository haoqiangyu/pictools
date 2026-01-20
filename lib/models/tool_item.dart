import 'package:flutter/material.dart';

/// 工具项数据模型
class ToolItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String routeName;

  const ToolItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.routeName,
  });
}

/// 预定义的工具列表
class Tools {
  Tools._();

  static const List<ToolItem> all = [
    ToolItem(
      id: 'image_compare',
      name: '图片对比',
      description: '对比两张图片，清晰展示差异，支持多种对比模式',
      icon: Icons.compare,
      routeName: '/image-compare',
    ),
    ToolItem(
      id: 'image_adjust',
      name: '图片调整',
      description: '调整图片尺寸，按比例裁剪，快速获得所需效果',
      icon: Icons.crop,
      routeName: '/image-adjust',
    ),
    ToolItem(
      id: 'image_enhance',
      name: '亮度增强',
      description: '一键提升图片亮度，改善暗部细节，让画面更通透',
      icon: Icons.wb_sunny,
      routeName: '/image-enhance',
    ),
    ToolItem(
      id: 'ai_image',
      name: 'AI 图片修改',
      description: '使用 Gemini AI 根据提示词修改图片，支持多种宽高比和分辨率',
      icon: Icons.auto_awesome,
      routeName: '/ai-image',
    ),
  ];
}
