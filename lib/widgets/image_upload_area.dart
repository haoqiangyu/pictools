import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../theme/app_theme.dart';

/// 图片上传区域组件
class ImageUploadArea extends StatefulWidget {
  final String label;
  final Uint8List? imageData;
  final String? fileName;
  final String? filePath;
  final VoidCallback? onClear;
  final void Function(Uint8List data, String name, String? path)?
  onImageSelected;

  const ImageUploadArea({
    super.key,
    required this.label,
    this.imageData,
    this.fileName,
    this.filePath,
    this.onClear,
    this.onImageSelected,
  });

  @override
  State<ImageUploadArea> createState() => _ImageUploadAreaState();
}

/// 记住上次选择的目录
String? _lastPickedDirectory;

class _ImageUploadAreaState extends State<ImageUploadArea> {
  bool _isDragging = false;
  bool _isHovering = false;
  bool _showControls = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
        initialDirectory: _lastPickedDirectory,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // 记住目录路径
        if (file.path != null) {
          final lastSlash = file.path!.lastIndexOf('/');
          if (lastSlash > 0) {
            _lastPickedDirectory = file.path!.substring(0, lastSlash);
          }
        }

        if (file.bytes != null) {
          widget.onImageSelected?.call(file.bytes!, file.name, file.path);
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  void _handleDrop(DropDoneDetails details) {
    if (details.files.isNotEmpty) {
      final file = details.files.first;
      file.readAsBytes().then((bytes) {
        widget.onImageSelected?.call(bytes, file.name, file.path);
      });
    }
    setState(() => _isDragging = false);
  }

  void _copyPath() {
    if (widget.filePath != null) {
      Clipboard.setData(ClipboardData(text: widget.filePath!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('路径已复制到剪贴板'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageData != null;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDrop,
      child: MouseRegion(
        onEnter: (_) => setState(() {
          _isHovering = true;
          if (hasImage) _showControls = true;
        }),
        onExit: (_) => setState(() {
          _isHovering = false;
          _showControls = false;
        }),
        cursor: hasImage ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: hasImage ? null : _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _isDragging
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragging
                    ? AppTheme.accentColor
                    : _isHovering && !hasImage
                    ? AppTheme.accentColor.withValues(alpha: 0.5)
                    : AppTheme.borderColor,
                width: _isDragging ? 2 : 1,
              ),
            ),
            child: hasImage ? _buildImagePreview() : _buildUploadPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: _isDragging
            ? AppTheme.accentColor
            : _isHovering
            ? AppTheme.accentColor.withValues(alpha: 0.5)
            : AppTheme.borderColor,
        strokeWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        radius: 12,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: _isDragging || _isHovering
                  ? AppTheme.accentColor
                  : AppTheme.secondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '拖拽或点击上传',
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        // 图片预览 (全尺寸)
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(widget.imageData!, fit: BoxFit.contain),
          ),
        ),

        // 悬浮控制条 (底部，仅悬停时显示)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: 0,
          right: 0,
          bottom: _showControls ? 0 : -50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.primaryBg.withValues(alpha: 0.95),
                  AppTheme.primaryBg.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 1.0],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // 文件名 (紧凑显示)
                Expanded(
                  child: GestureDetector(
                    onTap: _copyPath,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: widget.filePath ?? widget.fileName ?? '',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 12,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.fileName ?? widget.label,
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 复制路径按钮
                if (widget.filePath != null)
                  _IconButton(
                    icon: Icons.content_copy,
                    tooltip: '复制路径',
                    size: 24,
                    onTap: _copyPath,
                  ),
                // 替换按钮
                _IconButton(
                  icon: Icons.swap_horiz,
                  tooltip: '替换图片',
                  size: 24,
                  onTap: _pickImage,
                ),
                // 删除按钮
                _IconButton(
                  icon: Icons.close,
                  tooltip: '删除图片',
                  size: 24,
                  color: AppTheme.errorColor,
                  onTap: widget.onClear,
                ),
              ],
            ),
          ),
        ),

        // 角标 (始终显示，标识图片类型)
        Positioned(
          left: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 小型图标按钮
class _IconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    this.size = 28,
    this.color,
    this.onTap,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.textColor;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isHovering
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.6,
              color: _isHovering ? color : AppTheme.secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 虚线边框绘制器
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = dashWidth;
        result.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace ||
        radius != oldDelegate.radius;
  }
}
