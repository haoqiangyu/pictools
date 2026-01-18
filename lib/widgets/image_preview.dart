import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'crop_overlay.dart';

/// 图片预览组件
class ImagePreview extends StatelessWidget {
  /// 图片数据
  final Uint8List imageData;

  /// 是否显示裁剪遮罩
  final bool showCropOverlay;

  /// 裁剪区域（归一化坐标 0-1）
  final Rect cropRect;

  /// 裁剪区域变化回调
  final ValueChanged<Rect>? onCropRectChanged;

  /// 目标比例（null 表示自由裁剪）
  final double? aspectRatio;

  /// 目标尺寸（用于尺寸调整模式显示）
  final Size? targetSize;

  /// 原始尺寸
  final Size? originalSize;

  const ImagePreview({
    super.key,
    required this.imageData,
    this.showCropOverlay = false,
    this.cropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.onCropRectChanged,
    this.aspectRatio,
    this.targetSize,
    this.originalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景棋盘格（显示透明区域）
            Positioned.fill(
              child: CustomPaint(painter: _CheckerboardPainter()),
            ),

            // 图片
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Image.memory(
                    imageData,
                    fit: BoxFit.contain,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (frame == null) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentColor,
                              ),
                            );
                          }

                          // 获取图片实际渲染尺寸
                          return LayoutBuilder(
                            builder: (context, innerConstraints) {
                              return Stack(
                                children: [
                                  child,
                                  if (showCropOverlay)
                                    Positioned.fill(
                                      child: CropOverlay(
                                        imageSize:
                                            originalSize ??
                                            const Size(100, 100),
                                        cropRect: cropRect,
                                        onCropRectChanged: onCropRectChanged,
                                        aspectRatio: aspectRatio,
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                  );
                },
              ),
            ),

            // 尺寸信息显示
            if (targetSize != null && originalSize != null)
              Positioned(left: 12, bottom: 12, child: _buildSizeInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeInfo() {
    final isChanged = targetSize != originalSize;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChanged) ...[
            Text(
              '${originalSize!.width.toInt()} × ${originalSize!.height.toInt()}',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 11,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              size: 12,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '${targetSize!.width.toInt()} × ${targetSize!.height.toInt()}',
            style: TextStyle(
              color: isChanged ? AppTheme.accentColor : AppTheme.textColor,
              fontSize: 11,
              fontWeight: isChanged ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// 棋盘格绘制器（用于显示透明区域）
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 10.0;
    final lightPaint = Paint()..color = const Color(0xFF2A2A2A);
    final darkPaint = Paint()..color = const Color(0xFF1A1A1A);

    for (double x = 0; x < size.width; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        final isLight =
            ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
