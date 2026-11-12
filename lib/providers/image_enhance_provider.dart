import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/export_format.dart';
import '../services/image_processing_service.dart';

/// 图片亮度增强状态管理
class ImageEnhanceProvider extends ChangeNotifier {
  ImageEnhanceProvider({Future<Uint8List> Function(Uint8List)? enhancer})
    : _enhancer = enhancer ?? ImageProcessingService.enhance;
  final Future<Uint8List> Function(Uint8List) _enhancer;
  int _generation = 0, _loadGeneration = 0;
  @override
  void dispose() {
    _generation++;
    _loadGeneration++;
    super.dispose();
  }

  /// 原始图片数据
  Uint8List? _originalData;
  Uint8List? get originalData => _originalData;

  /// 增强后的图片数据
  Uint8List? _enhancedData;
  Uint8List? get enhancedData => _enhancedData;

  /// 文件名
  String? _fileName;
  String? get fileName => _fileName;

  /// 文件路径
  String? _filePath;
  String? get filePath => _filePath;

  /// 原始图片尺寸
  Size? _originalSize;
  Size? get originalSize => _originalSize;

  /// 处理状态
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 是否有图片
  bool get hasImage => _originalData != null;

  /// 是否已处理
  bool get hasEnhanced => _enhancedData != null;

  /// 导出格式
  ExportFormat _exportFormat = ExportFormat.png;
  ExportFormat get exportFormat => _exportFormat;

  /// 设置图片
  Future<void> setImage(Uint8List data, {String? name, String? path}) async {
    final generation = ++_loadGeneration;
    // 解码获取原始尺寸
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();
    if (generation != _loadGeneration) return;
    _generation++;
    _originalData = data;
    _fileName = name;
    _filePath = path;
    _enhancedData = null;
    _errorMessage = null;

    _originalSize = size;
    _isProcessing = false;

    notifyListeners();
  }

  Future<void> enhance() async {
    if (_originalData == null || _isProcessing) return;
    final generation = _generation;
    final data = _originalData!;
    startProcessing();
    try {
      final result = await _enhancer(data);
      if (generation == _generation) setEnhancedData(result);
    } catch (_) {
      if (generation == _generation) setError('enhanceError');
    }
  }

  /// 设置增强后的图片
  void setEnhancedData(Uint8List data) {
    _enhancedData = data;
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 开始处理
  void startProcessing() {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// 处理失败
  void setError(String message) {
    _isProcessing = false;
    _errorMessage = message;
    notifyListeners();
  }

  /// 设置导出格式
  void setExportFormat(ExportFormat format) {
    _exportFormat = format;
    notifyListeners();
  }

  /// 清除图片
  void clearImage() {
    _generation++;
    _loadGeneration++;
    _originalData = null;
    _enhancedData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// 完全重置
  void reset() {
    _generation++;
    _loadGeneration++;
    _originalData = null;
    _enhancedData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _isProcessing = false;
    _errorMessage = null;
    _exportFormat = ExportFormat.png;
    notifyListeners();
  }

  /// 导出状态
  Future<Map<String, dynamic>> exportState() async {
    String? originalPath = _filePath;
    if (originalPath == null && _originalData != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_enhance_origin_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_originalData!);
        originalPath = file.path;
      } catch (e) {
        debugPrint('Failed to save temp original image: $e');
      }
    }

    String? enhancedPath;
    if (_enhancedData != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_enhance_result_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_enhancedData!);
        enhancedPath = file.path;
      } catch (e) {
        debugPrint('Failed to save temp enhanced image: $e');
      }
    }

    return {
      'filePath': originalPath,
      'enhancedPath': enhancedPath,
      'fileName': _fileName,
      'exportFormat': _exportFormat.index,
    };
  }

  /// 导入状态
  Future<void> importState(Map<String, dynamic> state) async {
    if (state['filePath'] != null) {
      final path = state['filePath'] as String;
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await setImage(bytes, name: state['fileName'], path: path);
        }
      } catch (e) {
        debugPrint('Failed to load original image: $e');
      }
    }

    if (state['enhancedPath'] != null) {
      final path = state['enhancedPath'] as String;
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _enhancedData = bytes;
          // 恢复后不再是处理中
          _isProcessing = false;
          _errorMessage = null;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Failed to load enhanced image: $e');
      }
    }

    if (state['exportFormat'] != null) {
      setExportFormat(ExportFormat.values[state['exportFormat']]);
    }
  }
}
