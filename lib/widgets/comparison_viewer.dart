import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/comparison_mode.dart';
import 'slider_comparison.dart';
import 'side_by_side_comparison.dart';
import 'overlay_comparison.dart';

/// 对比查看器组件
/// 根据当前模式渲染对应的对比视图
class ComparisonViewer extends StatelessWidget {
  final Uint8List imageA;
  final Uint8List imageB;
  final ComparisonMode mode;
  final double sliderPosition;
  final double overlayOpacity;
  final ValueChanged<double>? onSliderChanged;

  const ComparisonViewer({
    super.key,
    required this.imageA,
    required this.imageB,
    required this.mode,
    this.sliderPosition = 0.5,
    this.overlayOpacity = 0.5,
    this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ComparisonMode.slider:
        return SliderComparison(
          imageA: imageA,
          imageB: imageB,
          sliderPosition: sliderPosition,
          onSliderChanged: onSliderChanged,
        );
      case ComparisonMode.sideBySide:
        return SideBySideComparison(imageA: imageA, imageB: imageB);
      case ComparisonMode.overlay:
        return OverlayComparison(
          imageA: imageA,
          imageB: imageB,
          opacity: overlayOpacity,
        );
    }
  }
}
