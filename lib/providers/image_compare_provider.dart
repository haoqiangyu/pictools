import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/comparison_mode.dart';

/// 图片对比状态管理
class ImageCompareProvider extends ChangeNotifier {
  /// 图片 A 的数据
  Uint8List? _imageA;
  Uint8List? get imageA => _imageA;

  /// 图片 B 的数据
  Uint8List? _imageB;
  Uint8List? get imageB => _imageB;

  /// 图片 A 的文件名
  String? _imageAName;
  String? get imageAName => _imageAName;

  /// 图片 B 的文件名
  String? _imageBName;
  String? get imageBName => _imageBName;

  /// 图片 A 的文件路径
  String? _imageAPath;
  String? get imageAPath => _imageAPath;

  /// 图片 B 的文件路径
  String? _imageBPath;
  String? get imageBPath => _imageBPath;

  /// 当前对比模式
  ComparisonMode _mode = ComparisonMode.slider;
  ComparisonMode get mode => _mode;

  /// 叠加模式的透明度 (0.0 - 1.0)
  double _overlayOpacity = 0.5;
  double get overlayOpacity => _overlayOpacity;

  /// 滑块位置 (0.0 - 1.0)
  double _sliderPosition = 0.5;
  double get sliderPosition => _sliderPosition;

  /// 是否两张图片都已加载
  bool get hasBothImages => _imageA != null && _imageB != null;

  /// 设置图片 A
  void setImageA(Uint8List? data, {String? name, String? path}) {
    _imageA = data;
    _imageAName = name;
    _imageAPath = path;
    notifyListeners();
  }

  /// 设置图片 B
  void setImageB(Uint8List? data, {String? name, String? path}) {
    _imageB = data;
    _imageBName = name;
    _imageBPath = path;
    notifyListeners();
  }

  /// 清除图片 A
  void clearImageA() {
    _imageA = null;
    _imageAName = null;
    _imageAPath = null;
    notifyListeners();
  }

  /// 清除图片 B
  void clearImageB() {
    _imageB = null;
    _imageBName = null;
    _imageBPath = null;
    notifyListeners();
  }

  /// 设置对比模式
  void setMode(ComparisonMode mode) {
    _mode = mode;
    notifyListeners();
  }

  /// 设置叠加透明度
  void setOverlayOpacity(double opacity) {
    _overlayOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 设置滑块位置
  void setSliderPosition(double position) {
    _sliderPosition = position.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 重置所有状态
  void reset() {
    _imageA = null;
    _imageB = null;
    _imageAName = null;
    _imageBName = null;
    _imageAPath = null;
    _imageBPath = null;
    _mode = ComparisonMode.slider;
    _overlayOpacity = 0.5;
    _sliderPosition = 0.5;
    notifyListeners();
  }

  /// 导出状态
  Future<Map<String, dynamic>> exportState() async {
    String? pathA = _imageAPath;
    if (pathA == null && _imageA != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_temp_a_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_imageA!);
        pathA = file.path;
      } catch (e) {
        debugPrint('Failed to save temp image A: $e');
      }
    }

    String? pathB = _imageBPath;
    if (pathB == null && _imageB != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_temp_b_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_imageB!);
        pathB = file.path;
      } catch (e) {
        debugPrint('Failed to save temp image B: $e');
      }
    }

    return {
      'imageAPath': pathA,
      'imageAName': _imageAName ?? 'Temp Image A',
      'imageBPath': pathB,
      'imageBName': _imageBName ?? 'Temp Image B',
      'mode': _mode.index,
      'sliderPosition': _sliderPosition,
      'overlayOpacity': _overlayOpacity,
    };
  }

  /// 导入状态
  Future<void> importState(Map<String, dynamic> state) async {
    if (state['imageAPath'] != null) {
      final path = state['imageAPath'] as String;
      try {
        // 读取本地文件，需要导入 dart:io
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setImageA(bytes, name: state['imageAName'], path: path);
        }
      } catch (e) {
        debugPrint('Failed to load image A: $e');
      }
    }

    if (state['imageBPath'] != null) {
      final path = state['imageBPath'] as String;
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setImageB(bytes, name: state['imageBName'], path: path);
        }
      } catch (e) {
        debugPrint('Failed to load image B: $e');
      }
    }

    if (state['mode'] != null) {
      setMode(ComparisonMode.values[state['mode']]);
    }
    if (state['sliderPosition'] != null) {
      setSliderPosition(state['sliderPosition']);
    }
    if (state['overlayOpacity'] != null) {
      setOverlayOpacity(state['overlayOpacity']);
    }
  }
}
