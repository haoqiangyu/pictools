/// 对比模式枚举
enum ComparisonMode {
  /// 滑块对比模式
  slider,
  /// 并排对比模式
  sideBySide,
  /// 叠加对比模式
  overlay,
}

extension ComparisonModeExtension on ComparisonMode {
  String get displayName {
    switch (this) {
      case ComparisonMode.slider:
        return '滑块';
      case ComparisonMode.sideBySide:
        return '并排';
      case ComparisonMode.overlay:
        return '叠加';
    }
  }

  String get icon {
    switch (this) {
      case ComparisonMode.slider:
        return '⇔';
      case ComparisonMode.sideBySide:
        return '▣';
      case ComparisonMode.overlay:
        return '◐';
    }
  }
}
