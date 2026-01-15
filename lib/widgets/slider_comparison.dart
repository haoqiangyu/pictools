import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 滑块对比模式组件
class SliderComparison extends StatefulWidget {
  final Uint8List imageA;
  final Uint8List imageB;
  final double sliderPosition;
  final ValueChanged<double>? onSliderChanged;

  const SliderComparison({
    super.key,
    required this.imageA,
    required this.imageB,
    this.sliderPosition = 0.5,
    this.onSliderChanged,
  });

  @override
  State<SliderComparison> createState() => _SliderComparisonState();
}

class _SliderComparisonState extends State<SliderComparison> {
  late double _position;
  bool _isDragging = false;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _position = widget.sliderPosition;
    _decodeImageSize();
  }

  @override
  void didUpdateWidget(SliderComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sliderPosition != widget.sliderPosition) {
      _position = widget.sliderPosition;
    }
    if (oldWidget.imageA != widget.imageA) {
      _decodeImageSize();
    }
  }

  Future<void> _decodeImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageA);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
    frame.image.dispose();
    codec.dispose();
  }

  Rect _calculateImageRect(Size containerSize) {
    if (_imageSize == null) {
      return Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }

    final imageAspect = _imageSize!.width / _imageSize!.height;
    final containerAspect = containerSize.width / containerSize.height;

    double renderWidth, renderHeight;
    if (imageAspect > containerAspect) {
      renderWidth = containerSize.width;
      renderHeight = containerSize.width / imageAspect;
    } else {
      renderHeight = containerSize.height;
      renderWidth = containerSize.height * imageAspect;
    }

    final offsetX = (containerSize.width - renderWidth) / 2;
    final offsetY = (containerSize.height - renderHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);
  }

  void _updatePosition(double localX, Rect imageRect) {
    // Constrain to image bounds
    final clampedX = localX.clamp(imageRect.left, imageRect.right);
    final newPosition = (clampedX - imageRect.left) / imageRect.width;
    setState(() => _position = newPosition.clamp(0.0, 1.0));
    widget.onSliderChanged?.call(_position);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _calculateImageRect(containerSize);

        final sliderX = imageRect.left + (_position * imageRect.width);

        return MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() => _isDragging = true);
              _updatePosition(details.localPosition.dx, imageRect);
            },
            onHorizontalDragUpdate: (details) {
              _updatePosition(details.localPosition.dx, imageRect);
            },
            onHorizontalDragEnd: (_) {
              setState(() => _isDragging = false);
            },
            onTapDown: (details) {
              _updatePosition(details.localPosition.dx, imageRect);
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Stack(
                children: [
                  // 图片 B (底层，完整显示)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        widget.imageB,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  // 图片 A (顶层，裁剪显示)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _ImageClipper(imageRect, _position),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          widget.imageA,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  // 分割线
                  Positioned(
                    left: sliderX - 1,
                    top: imageRect.top,
                    height: imageRect.height,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 拖动手柄 (更小的尺寸)
                  Positioned(
                    left: sliderX - 14,
                    top: imageRect.top + (imageRect.height / 2) - 14,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? AppTheme.accentColor
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.code,
                        color: _isDragging ? Colors.white : AppTheme.primaryBg,
                        size: 14,
                      ),
                    ),
                  ),
                  // 标签
                  Positioned(
                    left: imageRect.left + 8,
                    bottom: imageRect.top + 8,
                    child: _buildLabel('原图 A'),
                  ),
                  Positioned(
                    right: (containerSize.width - imageRect.right) + 8,
                    bottom: imageRect.top + 8,
                    child: _buildLabel('对比图 B'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 图片裁剪器 - 只裁剪图片区域
class _ImageClipper extends CustomClipper<Rect> {
  final Rect imageRect;
  final double position;

  _ImageClipper(this.imageRect, this.position);

  @override
  Rect getClip(Size size) {
    final clipWidth = imageRect.left + (position * imageRect.width);
    return Rect.fromLTWH(0, 0, clipWidth, size.height);
  }

  @override
  bool shouldReclip(covariant _ImageClipper oldClipper) {
    return imageRect != oldClipper.imageRect || position != oldClipper.position;
  }
}
