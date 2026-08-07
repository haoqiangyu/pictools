import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 裁剪遮罩层组件
class CropOverlay extends StatefulWidget {
  /// 图片显示区域
  final Size imageSize;

  /// 裁剪区域（归一化坐标 0-1）
  final Rect cropRect;

  /// 裁剪区域变化回调
  final ValueChanged<Rect>? onCropRectChanged;

  /// 目标比例（null 表示自由裁剪）
  final double? aspectRatio;

  const CropOverlay({
    super.key,
    required this.imageSize,
    required this.cropRect,
    this.onCropRectChanged,
    this.aspectRatio,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  Rect? _dragStartRect;
  Offset? _dragStartPosition;
  _HandlePosition? _activeHandle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final cropRectPixels = _normalizedToPixels(widget.cropRect, viewSize);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 半透明遮罩
            ..._buildMaskRegions(viewSize, cropRectPixels),

            // 裁剪区域边框
            Positioned.fromRect(
              rect: cropRectPixels,
              child: GestureDetector(
                onPanStart: (details) => _onPanStart(details, null, viewSize),
                onPanUpdate: (details) => _onPanUpdate(details, viewSize),
                onPanEnd: (_) => _onPanEnd(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _buildGridLines(),
                  ),
                ),
              ),
            ),

            // 拖拽控制柄
            ..._buildHandles(cropRectPixels, viewSize),
          ],
        );
      },
    );
  }

  List<Widget> _buildMaskRegions(Size viewSize, Rect cropRect) {
    const maskColor = Color(0xAA000000);
    return [
      // 上方遮罩
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: cropRect.top,
        child: Container(color: maskColor),
      ),
      // 下方遮罩
      Positioned(
        left: 0,
        top: cropRect.bottom,
        right: 0,
        bottom: 0,
        child: Container(color: maskColor),
      ),
      // 左侧遮罩
      Positioned(
        left: 0,
        top: cropRect.top,
        width: cropRect.left,
        height: cropRect.height,
        child: Container(color: maskColor),
      ),
      // 右侧遮罩
      Positioned(
        left: cropRect.right,
        top: cropRect.top,
        right: 0,
        height: cropRect.height,
        child: Container(color: maskColor),
      ),
    ];
  }

  Widget _buildGridLines() {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }

  List<Widget> _buildHandles(Rect cropRect, Size viewSize) {
    const visualSize = 14.0;
    const touchTargetSize = 48.0;
    final handles = <Widget>[];

    // 有锁定比例时只显示四个角
    final positions = widget.aspectRatio != null
        ? {
            _HandlePosition.topLeft: cropRect.topLeft,
            _HandlePosition.topRight: cropRect.topRight,
            _HandlePosition.bottomLeft: cropRect.bottomLeft,
            _HandlePosition.bottomRight: cropRect.bottomRight,
          }
        : {
            _HandlePosition.top: Offset(cropRect.center.dx, cropRect.top),
            _HandlePosition.bottom: Offset(cropRect.center.dx, cropRect.bottom),
            _HandlePosition.left: Offset(cropRect.left, cropRect.center.dy),
            _HandlePosition.right: Offset(cropRect.right, cropRect.center.dy),
            // Corners come last so they win hit testing where targets overlap.
            _HandlePosition.topLeft: cropRect.topLeft,
            _HandlePosition.topRight: cropRect.topRight,
            _HandlePosition.bottomLeft: cropRect.bottomLeft,
            _HandlePosition.bottomRight: cropRect.bottomRight,
          };

    for (final entry in positions.entries) {
      final pos = entry.key;
      final offset = entry.value;
      final targetLeft = (offset.dx - touchTargetSize / 2)
          .clamp(0.0, math.max(0.0, viewSize.width - touchTargetSize))
          .toDouble();
      final targetTop = (offset.dy - touchTargetSize / 2)
          .clamp(0.0, math.max(0.0, viewSize.height - touchTargetSize))
          .toDouble();

      handles.add(
        Positioned(
          left: targetLeft,
          top: targetTop,
          width: math.min(touchTargetSize, viewSize.width),
          height: math.min(touchTargetSize, viewSize.height),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => _onPanStart(details, pos, viewSize),
            onPanUpdate: (details) => _onPanUpdate(details, viewSize),
            onPanEnd: (_) => _onPanEnd(),
            child: MouseRegion(
              cursor: _getCursor(pos),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: offset.dx - targetLeft - visualSize / 2,
                    top: offset.dy - targetTop - visualSize / 2,
                    child: Container(
                      width: visualSize,
                      height: visualSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.accentColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return handles;
  }

  MouseCursor _getCursor(_HandlePosition pos) {
    switch (pos) {
      case _HandlePosition.topLeft:
      case _HandlePosition.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case _HandlePosition.topRight:
      case _HandlePosition.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case _HandlePosition.top:
      case _HandlePosition.bottom:
        return SystemMouseCursors.resizeUpDown;
      case _HandlePosition.left:
      case _HandlePosition.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  void _onPanStart(
    DragStartDetails details,
    _HandlePosition? handle,
    Size viewSize,
  ) {
    _dragStartRect = widget.cropRect;
    _dragStartPosition = details.globalPosition;
    _activeHandle = handle;
  }

  void _onPanUpdate(DragUpdateDetails details, Size viewSize) {
    if (_dragStartRect == null || _dragStartPosition == null) return;

    final delta = details.globalPosition - _dragStartPosition!;
    final normalizedDelta = Offset(
      delta.dx / viewSize.width,
      delta.dy / viewSize.height,
    );

    Rect newRect;

    if (_activeHandle == null) {
      // 移动整个裁剪区域
      newRect = _dragStartRect!.translate(
        normalizedDelta.dx,
        normalizedDelta.dy,
      );
      // 限制在图片范围内
      double left = newRect.left.clamp(0.0, 1.0 - newRect.width);
      double top = newRect.top.clamp(0.0, 1.0 - newRect.height);
      newRect = Rect.fromLTWH(left, top, newRect.width, newRect.height);
    } else {
      // 调整裁剪区域大小
      newRect = _resizeRect(normalizedDelta, viewSize);
    }

    widget.onCropRectChanged?.call(newRect);
  }

  Rect _resizeRect(Offset delta, Size viewSize) {
    double left = _dragStartRect!.left;
    double top = _dragStartRect!.top;
    double right = _dragStartRect!.right;
    double bottom = _dragStartRect!.bottom;

    const minSize = 0.1;

    if (widget.aspectRatio != null) {
      // 锁定比例模式：根据拖动距离计算新尺寸
      return _resizeWithAspectRatio(delta, viewSize);
    }

    // 自由裁剪模式
    switch (_activeHandle!) {
      case _HandlePosition.topLeft:
        left += delta.dx;
        top += delta.dy;
      case _HandlePosition.topRight:
        right += delta.dx;
        top += delta.dy;
      case _HandlePosition.bottomLeft:
        left += delta.dx;
        bottom += delta.dy;
      case _HandlePosition.bottomRight:
        right += delta.dx;
        bottom += delta.dy;
      case _HandlePosition.top:
        top += delta.dy;
      case _HandlePosition.bottom:
        bottom += delta.dy;
      case _HandlePosition.left:
        left += delta.dx;
      case _HandlePosition.right:
        right += delta.dx;
    }

    // 确保最小尺寸
    if (right - left < minSize) {
      if (_activeHandle!.name.contains('left')) {
        left = right - minSize;
      } else {
        right = left + minSize;
      }
    }
    if (bottom - top < minSize) {
      if (_activeHandle!.name.contains('top')) {
        top = bottom - minSize;
      } else {
        bottom = top + minSize;
      }
    }

    return Rect.fromLTRB(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      right.clamp(0.0, 1.0),
      bottom.clamp(0.0, 1.0),
    );
  }

  Rect _resizeWithAspectRatio(Offset delta, Size viewSize) {
    final aspectRatio = widget.aspectRatio!;
    final startRect = _dragStartRect!;

    // 计算拖动的主方向距离（沿对角线）
    double dragDistance;

    switch (_activeHandle!) {
      case _HandlePosition.topLeft:
        // 向左上拖动为扩大，向右下拖动为缩小
        dragDistance = (-delta.dx - delta.dy) / 2;
      case _HandlePosition.topRight:
        // 向右上拖动为扩大，向左下拖动为缩小
        dragDistance = (delta.dx - delta.dy) / 2;
      case _HandlePosition.bottomLeft:
        // 向左下拖动为扩大，向右上拖动为缩小
        dragDistance = (-delta.dx + delta.dy) / 2;
      case _HandlePosition.bottomRight:
        // 向右下拖动为扩大，向左上拖动为缩小
        dragDistance = (delta.dx + delta.dy) / 2;
      default:
        return startRect;
    }

    // 计算新的宽度
    double newWidth = startRect.width + dragDistance;
    newWidth = newWidth.clamp(0.1, 1.0);

    // 根据比例计算高度
    double newHeight = newWidth / aspectRatio;

    // 确保高度也在有效范围内
    if (newHeight > 1.0) {
      newHeight = 1.0;
      newWidth = newHeight * aspectRatio;
    }
    if (newHeight < 0.1) {
      newHeight = 0.1;
      newWidth = newHeight * aspectRatio;
    }

    // 根据拖动的角计算新的位置
    double newLeft, newTop;

    switch (_activeHandle!) {
      case _HandlePosition.topLeft:
        // 右下角固定
        newLeft = startRect.right - newWidth;
        newTop = startRect.bottom - newHeight;
      case _HandlePosition.topRight:
        // 左下角固定
        newLeft = startRect.left;
        newTop = startRect.bottom - newHeight;
      case _HandlePosition.bottomLeft:
        // 右上角固定
        newLeft = startRect.right - newWidth;
        newTop = startRect.top;
      case _HandlePosition.bottomRight:
        // 左上角固定
        newLeft = startRect.left;
        newTop = startRect.top;
      default:
        newLeft = startRect.left;
        newTop = startRect.top;
    }

    // 边界检查
    if (newLeft < 0) {
      newLeft = 0;
      newWidth = math.min(newWidth, 1.0);
      newHeight = newWidth / aspectRatio;
    }
    if (newTop < 0) {
      newTop = 0;
      newHeight = math.min(newHeight, 1.0);
      newWidth = newHeight * aspectRatio;
    }
    if (newLeft + newWidth > 1.0) {
      newWidth = 1.0 - newLeft;
      newHeight = newWidth / aspectRatio;
    }
    if (newTop + newHeight > 1.0) {
      newHeight = 1.0 - newTop;
      newWidth = newHeight * aspectRatio;
    }

    return Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
  }

  void _onPanEnd() {
    _dragStartRect = null;
    _dragStartPosition = null;
    _activeHandle = null;
  }

  Rect _normalizedToPixels(Rect normalized, Size size) {
    return Rect.fromLTRB(
      normalized.left * size.width,
      normalized.top * size.height,
      normalized.right * size.width,
      normalized.bottom * size.height,
    );
  }
}

enum _HandlePosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right;

  bool get isCorner =>
      this == topLeft ||
      this == topRight ||
      this == bottomLeft ||
      this == bottomRight;
}

/// 网格线绘制器
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    // 三分线
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
