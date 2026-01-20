import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/internal_clipboard_service.dart';
import '../theme/app_theme.dart';
import 'image_context_menu.dart';

/// 带右键菜单的图片展示区域包装器
///
/// 用于各个功能屏幕中的图片面板，添加右键复制功能
class ImagePanelWithMenu extends StatelessWidget {
  final Widget child;
  final Uint8List? imageData;
  final String? fileName;
  final String? filePath;

  const ImagePanelWithMenu({
    super.key,
    required this.child,
    this.imageData,
    this.fileName,
    this.filePath,
  });

  Future<void> _handleContextMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    if (imageData == null) return;

    await showImageContextMenu(
      context,
      details.globalPosition,
      imageData: imageData,
      fileName: fileName,
      filePath: filePath,
      onSelected: (action) async {
        if (action == ImageContextAction.copy) {
          await InternalClipboardService.instance.copyImage(
            imageData!,
            fileName: fileName,
            filePath: filePath,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 图片已复制到剪切板'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.highlightColor,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _handleContextMenu(context, details),
      child: child,
    );
  }
}
