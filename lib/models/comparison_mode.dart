import '../l10n/app_localizations.dart';

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
        return appText('mode.slider');
      case ComparisonMode.sideBySide:
        return appText('mode.sideBySide');
      case ComparisonMode.overlay:
        return appText('mode.overlay');
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
