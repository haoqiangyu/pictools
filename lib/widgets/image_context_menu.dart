import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/internal_clipboard_service.dart';

/// 图片右键菜单项
enum ImageContextAction { copy, paste }

/// 自定义图片右键菜单
class ImageContextMenu extends StatefulWidget {
  /// 当前图片数据（如果有）
  final Uint8List? imageData;

  /// 文件名（用于复制）
  final String? fileName;

  /// 文件路径（用于复制）
  final String? filePath;

  /// 菜单项选择回调
  final Future<void> Function(ImageContextAction action)? onSelected;

  const ImageContextMenu({
    super.key,
    this.imageData,
    this.fileName,
    this.filePath,
    this.onSelected,
  });

  @override
  State<ImageContextMenu> createState() => _ImageContextMenuState();
}

class _ImageContextMenuState extends State<ImageContextMenu> {
  ImageContextAction? _hoveredAction;

  @override
  Widget build(BuildContext context) {
    final canCopy = widget.imageData != null;

    return FutureBuilder<bool>(
      future: InternalClipboardService.instance.hasImage(),
      builder: (context, snapshot) {
        final canPaste = snapshot.data ?? false;

        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 复制选项
              if (canCopy)
                _buildMenuItem(
                  action: ImageContextAction.copy,
                  icon: Icons.content_copy,
                  label: '复制图片',
                  enabled: true,
                ),
              // 粘贴选项（可以替换现有图片）
              if (canPaste)
                _buildMenuItem(
                  action: ImageContextAction.paste,
                  icon: Icons.content_paste,
                  label: canCopy ? '粘贴替换' : '粘贴图片',
                  enabled: true,
                  showPreview: true,
                ),
              // 如果既不能复制也不能粘贴，显示提示
              if (!canCopy && !canPaste)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '剪切板为空',
                    style: TextStyle(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required ImageContextAction action,
    required IconData icon,
    required String label,
    required bool enabled,
    bool showPreview = false,
  }) {
    final isHovered = _hoveredAction == action;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAction = action),
      onExit: (_) => setState(() => _hoveredAction = null),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled
            ? () async {
                await widget.onSelected?.call(action);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled
                    ? (isHovered ? AppTheme.accentColor : AppTheme.textColor)
                    : AppTheme.secondaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled
                        ? (isHovered
                              ? AppTheme.accentColor
                              : AppTheme.textColor)
                        : AppTheme.secondaryColor.withValues(alpha: 0.3),
                    fontSize: 13,
                    fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              // 粘贴时显示缩略图预览
              if (showPreview && enabled) _buildThumbnail(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return FutureBuilder<ClipboardImage?>(
      future: InternalClipboardService.instance.currentImage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.memory(snapshot.data!.data, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

/// 显示图片右键菜单的辅助函数
Future<void> showImageContextMenu(
  BuildContext context,
  Offset position, {
  Uint8List? imageData,
  String? fileName,
  String? filePath,
  required Future<void> Function(ImageContextAction action) onSelected,
}) {
  return showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    color: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    items: [
      PopupMenuItem(
        enabled: false,
        padding: EdgeInsets.zero,
        child: ImageContextMenu(
          imageData: imageData,
          fileName: fileName,
          filePath: filePath,
          onSelected: onSelected,
        ),
      ),
    ],
  );
}
