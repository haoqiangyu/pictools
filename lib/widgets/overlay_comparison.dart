import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// 叠加对比模式组件
class OverlayComparison extends StatelessWidget {
  final Uint8List imageA;
  final Uint8List imageB;
  final double opacity;

  const OverlayComparison({
    super.key,
    required this.imageA,
    required this.imageB,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Stack(
        children: [
          // 图片 A (底层)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageA, fit: BoxFit.contain),
            ),
          ),
          // 图片 B (顶层，带透明度)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: opacity,
                child: Image.memory(imageB, fit: BoxFit.contain),
              ),
            ),
          ),
          // 标签
          Positioned(
            left: 12,
            bottom: 12,
            child: _buildLabel(context.l10n.t('overlayOriginal')),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _buildLabel(
              context.l10n
                  .t('overlayComparison')
                  .replaceAll('{opacity}', '${(opacity * 100).toInt()}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
