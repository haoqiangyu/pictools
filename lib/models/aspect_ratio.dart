import '../l10n/app_localizations.dart';

/// 裁剪比例预设枚举
enum AspectRatioPreset {
  /// 自由裁剪
  free,

  /// 1:1 正方形
  square,

  /// 4:3 横向
  ratio4x3,

  /// 3:4 纵向
  ratio3x4,

  /// 16:9 横向
  ratio16x9,

  /// 9:16 纵向
  ratio9x16,

  /// 3:2 横向
  ratio3x2,

  /// 2:3 纵向
  ratio2x3,
}

extension AspectRatioPresetExtension on AspectRatioPreset {
  String get displayName {
    switch (this) {
      case AspectRatioPreset.free:
        return appText('ratio.free');
      case AspectRatioPreset.square:
        return '1:1';
      case AspectRatioPreset.ratio4x3:
        return '4:3';
      case AspectRatioPreset.ratio3x4:
        return '3:4';
      case AspectRatioPreset.ratio16x9:
        return '16:9';
      case AspectRatioPreset.ratio9x16:
        return '9:16';
      case AspectRatioPreset.ratio3x2:
        return '3:2';
      case AspectRatioPreset.ratio2x3:
        return '2:3';
    }
  }

  /// 返回宽高比值，null 表示自由裁剪
  double? get ratio {
    switch (this) {
      case AspectRatioPreset.free:
        return null;
      case AspectRatioPreset.square:
        return 1.0;
      case AspectRatioPreset.ratio4x3:
        return 4.0 / 3.0;
      case AspectRatioPreset.ratio3x4:
        return 3.0 / 4.0;
      case AspectRatioPreset.ratio16x9:
        return 16.0 / 9.0;
      case AspectRatioPreset.ratio9x16:
        return 9.0 / 16.0;
      case AspectRatioPreset.ratio3x2:
        return 3.0 / 2.0;
      case AspectRatioPreset.ratio2x3:
        return 2.0 / 3.0;
    }
  }
}
