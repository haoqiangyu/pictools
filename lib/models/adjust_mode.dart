import '../l10n/app_localizations.dart';

/// 图片调整模式枚举
enum AdjustMode {
  /// 尺寸调整模式
  resize,

  /// 比例裁剪模式
  crop,
}

extension AdjustModeExtension on AdjustMode {
  String get displayName {
    switch (this) {
      case AdjustMode.resize:
        return appText('adjust.resize');
      case AdjustMode.crop:
        return appText('adjust.crop');
    }
  }

  String get description {
    switch (this) {
      case AdjustMode.resize:
        return appText('adjust.resizeDescription');
      case AdjustMode.crop:
        return appText('adjust.cropDescription');
    }
  }
}
