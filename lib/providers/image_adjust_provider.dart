import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/adjust_mode.dart';
import '../models/aspect_ratio.dart';

/// 图片调整状态管理
class ImageAdjustProvider extends ChangeNotifier {
  /// 图片原始数据
  Uint8List? _imageData;
  Uint8List? get imageData => _imageData;

  /// 文件名
  String? _fileName;
  String? get fileName => _fileName;

  /// 文件路径
  String? _filePath;
  String? get filePath => _filePath;

  /// 原始图片尺寸
  Size? _originalSize;
  Size? get originalSize => _originalSize;

  /// 当前调整模式
  AdjustMode _mode = AdjustMode.resize;
  AdjustMode get mode => _mode;

  /// 是否有图片
  bool get hasImage => _imageData != null;

  // ========== 尺寸调整相关 ==========

  /// 目标宽度
  int _targetWidth = 0;
  int get targetWidth => _targetWidth;

  /// 目标高度
  int _targetHeight = 0;
  int get targetHeight => _targetHeight;

  /// 是否锁定比例
  bool _lockAspectRatio = true;
  bool get lockAspectRatio => _lockAspectRatio;

  // ========== 比例裁剪相关 ==========

  /// 当前裁剪比例
  AspectRatioPreset _aspectRatio = AspectRatioPreset.free;
  AspectRatioPreset get aspectRatio => _aspectRatio;

  /// 裁剪区域（归一化坐标 0-1）
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
  Rect get cropRect => _cropRect;

  // ========== 导出相关 ==========

  /// 导出格式
  ExportFormat _exportFormat = ExportFormat.png;
  ExportFormat get exportFormat => _exportFormat;

  /// 设置图片
  Future<void> setImage(Uint8List data, {String? name, String? path}) async {
    _imageData = data;
    _fileName = name;
    _filePath = path;

    // 解码获取原始尺寸
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    _originalSize = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();

    // 初始化目标尺寸
    _targetWidth = _originalSize!.width.toInt();
    _targetHeight = _originalSize!.height.toInt();

    // 重置裁剪区域
    _cropRect = const Rect.fromLTWH(0, 0, 1, 1);

    notifyListeners();
  }

  /// 清除图片
  void clearImage() {
    _imageData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _targetWidth = 0;
    _targetHeight = 0;
    _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    notifyListeners();
  }

  /// 设置调整模式
  void setMode(AdjustMode mode) {
    _mode = mode;
    notifyListeners();
  }

  /// 设置目标宽度
  void setTargetWidth(int width) {
    if (width <= 0 || _originalSize == null) return;

    _targetWidth = width;
    if (_lockAspectRatio) {
      final ratio = _originalSize!.width / _originalSize!.height;
      _targetHeight = (width / ratio).round();
    }
    notifyListeners();
  }

  /// 设置目标高度
  void setTargetHeight(int height) {
    if (height <= 0 || _originalSize == null) return;

    _targetHeight = height;
    if (_lockAspectRatio) {
      final ratio = _originalSize!.width / _originalSize!.height;
      _targetWidth = (height * ratio).round();
    }
    notifyListeners();
  }

  /// 切换锁定比例
  void toggleLockAspectRatio() {
    _lockAspectRatio = !_lockAspectRatio;
    notifyListeners();
  }

  /// 设置锁定比例
  void setLockAspectRatio(bool lock) {
    _lockAspectRatio = lock;
    notifyListeners();
  }

  /// 应用预设尺寸
  void applyPresetSize(int width, int height) {
    _targetWidth = width;
    _targetHeight = height;
    _lockAspectRatio = false;
    notifyListeners();
  }

  /// 设置裁剪比例
  void setAspectRatio(AspectRatioPreset ratio) {
    _aspectRatio = ratio;

    // 根据比例重新计算裁剪区域
    if (ratio.ratio != null && _originalSize != null) {
      final imageRatio = _originalSize!.width / _originalSize!.height;
      final targetRatio = ratio.ratio!;

      double cropWidth, cropHeight;
      if (targetRatio > imageRatio) {
        // 目标比例更宽，以图片宽度为准
        cropWidth = 1.0;
        cropHeight = imageRatio / targetRatio;
      } else {
        // 目标比例更高，以图片高度为准
        cropHeight = 1.0;
        cropWidth = targetRatio / imageRatio;
      }

      // 居中裁剪区域
      _cropRect = Rect.fromCenter(
        center: const Offset(0.5, 0.5),
        width: cropWidth,
        height: cropHeight,
      );
    } else {
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    }

    notifyListeners();
  }

  /// 设置裁剪区域
  void setCropRect(Rect rect) {
    // 确保裁剪区域在有效范围内
    _cropRect = Rect.fromLTRB(
      rect.left.clamp(0.0, 1.0),
      rect.top.clamp(0.0, 1.0),
      rect.right.clamp(0.0, 1.0),
      rect.bottom.clamp(0.0, 1.0),
    );
    notifyListeners();
  }

  /// 设置导出格式
  void setExportFormat(ExportFormat format) {
    _exportFormat = format;
    notifyListeners();
  }

  /// 重置到原始状态
  void resetToOriginal() {
    if (_originalSize != null) {
      _targetWidth = _originalSize!.width.toInt();
      _targetHeight = _originalSize!.height.toInt();
      _lockAspectRatio = true;
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _aspectRatio = AspectRatioPreset.free;
      notifyListeners();
    }
  }

  /// 完全重置
  void reset() {
    _imageData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _mode = AdjustMode.resize;
    _targetWidth = 0;
    _targetHeight = 0;
    _lockAspectRatio = true;
    _aspectRatio = AspectRatioPreset.free;
    _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    _exportFormat = ExportFormat.png;
    notifyListeners();
  }
}
