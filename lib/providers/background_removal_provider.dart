import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/model_manager.dart';

/// 背景填充颜色
class BackgroundColor {
  final Color color;
  final String name;

  const BackgroundColor(this.color, this.name);

  static const List<BackgroundColor> presets = [
    BackgroundColor(Colors.white, '白色'),
    BackgroundColor(Colors.black, '黑色'),
    BackgroundColor(Color(0xFFFF0000), '红色'),
    BackgroundColor(Color(0xFF00FF00), '绿色'),
    BackgroundColor(Color(0xFF0000FF), '蓝色'),
  ];
}

/// 背景移除状态管理
class BackgroundRemovalProvider with ChangeNotifier {
  // 原始图片
  Uint8List? _originalData;
  String? _fileName;
  String? _filePath;
  Size? _originalSize;

  // 抠图结果
  Uint8List? _resultData;
  bool _isProcessing = false;
  String? _errorMessage;

  // 模型相关
  ModelPrecision _selectedPrecision = ModelPrecision.fp16;
  bool _isModelDownloaded = false;

  // 背景填充
  Color? _backgroundColor;
  Uint8List? _backgroundFilledData;

  // 导出格式
  ExportFormat _exportFormat = ExportFormat.png;

  final ModelManager _modelManager = ModelManager();

  // Getters
  Uint8List? get originalData => _originalData;
  String? get fileName => _fileName;
  String? get filePath => _filePath;
  Size? get originalSize => _originalSize;

  Uint8List? get resultData => _resultData;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  String? _modelPath;

  ModelPrecision get selectedPrecision => _selectedPrecision;
  bool get isModelDownloaded => _isModelDownloaded;
  String? get modelPath => _modelPath;

  Color? get backgroundColor => _backgroundColor;
  Uint8List? get backgroundFilledData => _backgroundFilledData;

  ExportFormat get exportFormat => _exportFormat;

  bool get hasImage => _originalData != null;
  bool get hasResult => _resultData != null;
  bool get hasBackgroundFilled => _backgroundFilledData != null;

  /// 检查模型是否已下载
  Future<void> checkModelDownloaded() async {
    _isModelDownloaded = await _modelManager.isModelDownloaded(
      _selectedPrecision,
    );
    _modelPath = await _modelManager.getModelPath(_selectedPrecision);
    notifyListeners();
  }

  /// 设置原始图片
  Future<void> setImage(Uint8List data, {String? name, String? path}) async {
    _originalData = data;
    _fileName = name;
    _filePath = path;
    _resultData = null;
    _backgroundColor = null;
    _backgroundFilledData = null;
    _errorMessage = null;

    // 获取图片尺寸
    final image = await decodeImageFromList(data);
    _originalSize = Size(image.width.toDouble(), image.height.toDouble());

    notifyListeners();
  }

  /// 设置选择的模型精度
  Future<void> setModelPrecision(ModelPrecision precision) async {
    _selectedPrecision = precision;
    await checkModelDownloaded();
  }

  /// 开始抠图处理
  void startProcessing() {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置抠图结果
  void setResult(Uint8List data) {
    _resultData = data;
    _isProcessing = false;
    _backgroundColor = null;
    _backgroundFilledData = null;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String error) {
    _errorMessage = error;
    _isProcessing = false;
    notifyListeners();
  }

  /// 设置背景颜色并填充
  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    _backgroundFilledData = null; // 清除之前的填充数据，需要重新生成
    notifyListeners();
  }

  /// 清除背景
  void clearBackground() {
    _backgroundColor = null;
    _backgroundFilledData = null;
    notifyListeners();
  }

  /// 设置背景填充结果
  void setBackgroundFilled(Uint8List data) {
    _backgroundFilledData = data;
    notifyListeners();
  }

  /// 设置导出格式
  void setExportFormat(ExportFormat format) {
    _exportFormat = format;
    notifyListeners();
  }

  /// 重置所有状态
  void reset() {
    _originalData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _resultData = null;
    _isProcessing = false;
    _errorMessage = null;
    _backgroundColor = null;
    _backgroundFilledData = null;
    notifyListeners();
  }

  /// 导出状态（用于多窗口）
  Future<Map<String, dynamic>> exportState() async {
    return {
      'originalData': _originalData,
      'fileName': _fileName,
      'filePath': _filePath,
      'resultData': _resultData,
      'selectedPrecision': _selectedPrecision.index,
      'backgroundColor': _backgroundColor?.toARGB32(),
      'exportFormat': _exportFormat.index,
    };
  }

  /// 导入状态（用于多窗口）
  Future<void> importState(Map<String, dynamic> state) async {
    if (state['originalData'] != null) {
      await setImage(
        state['originalData'] as Uint8List,
        name: state['fileName'] as String?,
        path: state['filePath'] as String?,
      );
    }
    if (state['resultData'] != null) {
      _resultData = state['resultData'] as Uint8List;
    }
    if (state['selectedPrecision'] != null) {
      _selectedPrecision =
          ModelPrecision.values[state['selectedPrecision'] as int];
      await checkModelDownloaded();
    }
    if (state['backgroundColor'] != null) {
      _backgroundColor = Color(state['backgroundColor'] as int);
    }
    if (state['exportFormat'] != null) {
      _exportFormat = ExportFormat.values[state['exportFormat'] as int];
    }
    notifyListeners();
  }
}

/// 导出格式
enum ExportFormat {
  png('PNG', 'png'),
  jpg('JPG', 'jpg');

  const ExportFormat(this.displayName, this.extension);

  final String displayName;
  final String extension;
}
