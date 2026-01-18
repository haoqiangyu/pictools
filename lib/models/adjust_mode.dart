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
        return '尺寸调整';
      case AdjustMode.crop:
        return '比例裁剪';
    }
  }

  String get description {
    switch (this) {
      case AdjustMode.resize:
        return '自定义图片宽高';
      case AdjustMode.crop:
        return '按比例裁剪图片';
    }
  }
}
