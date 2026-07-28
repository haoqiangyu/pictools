import 'package:flutter/material.dart';
import '../services/platform_capabilities.dart';

/// 工具项数据模型
class ToolItem {
  final String id;
  final IconData icon;
  final String routeName;

  const ToolItem({
    required this.id,
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
      icon: Icons.compare,
      routeName: '/image-compare',
    ),
    ToolItem(id: 'image_adjust', icon: Icons.crop, routeName: '/image-adjust'),
    ToolItem(
      id: 'image_enhance',
      icon: Icons.wb_sunny,
      routeName: '/image-enhance',
    ),
    ToolItem(
      id: 'background_removal',
      icon: Icons.auto_fix_high,
      routeName: '/background-removal',
    ),
    ToolItem(
      id: 'image_converter',
      icon: Icons.transform,
      routeName: '/image-converter',
    ),
  ];

  static List<ToolItem> get available =>
      PlatformCapabilities.supportsBackgroundRemoval
      ? all
      : all.where((tool) => tool.id != 'background_removal').toList();
}
