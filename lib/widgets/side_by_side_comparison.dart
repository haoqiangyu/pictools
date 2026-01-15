import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 并排对比模式组件
class SideBySideComparison extends StatelessWidget {
  final Uint8List imageA;
  final Uint8List imageB;

  const SideBySideComparison({
    super.key,
    required this.imageA,
    required this.imageB,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 图片 A
        Expanded(
          child: _buildImagePanel(
            imageData: imageA,
            label: '原图 A',
            isLeft: true,
          ),
        ),
        const SizedBox(width: 16),
        // 图片 B
        Expanded(
          child: _buildImagePanel(
            imageData: imageB,
            label: '对比图 B',
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePanel({
    required Uint8List imageData,
    required String label,
    required bool isLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Stack(
        children: [
          // 图片
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageData, fit: BoxFit.contain),
            ),
          ),
          // 标签
          Positioned(
            left: isLeft ? 12 : null,
            right: isLeft ? null : 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
