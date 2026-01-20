import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';

/// AI 图片修改状态
enum AIImageStatus { idle, processing, success, error }

/// AI 图片修改状态管理 Provider
class AIImageProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  /// 原始图片数据
  Uint8List? _originalData;
  Uint8List? get originalData => _originalData;

  /// 生成结果图片数据
  Uint8List? _resultData;
  Uint8List? get resultData => _resultData;

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
  AIImageStatus _status = AIImageStatus.idle;
  AIImageStatus get status => _status;

  /// 是否正在处理
  bool get isProcessing => _status == AIImageStatus.processing;

  /// 是否有图片
  bool get hasImage => _originalData != null;

  /// 是否有结果
  bool get hasResult => _resultData != null;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 提示词
  String _prompt = '';
  String get prompt => _prompt;

  /// 宽高比选项 (第一项为自适应)
  static const List<String> aspectRatioOptions = [
    '自适应',
    '1:1',
    '2:3',
    '3:2',
    '3:4',
    '4:3',
    '4:5',
    '5:4',
    '9:16',
    '16:9',
    '21:9',
  ];

  /// 当前选中的宽高比
  String _aspectRatio = '自适应';
  String get aspectRatio => _aspectRatio;

  /// 分辨率选项
  static const List<String> resolutionOptions = ['1K', '2K', '4K'];

  /// 当前选中的分辨率 (默认 1K)
  String _resolution = '1K';
  String get resolution => _resolution;

  /// 当前选中的模型
  GeminiModel _selectedModel = GeminiModel.defaultModel;
  GeminiModel get selectedModel => _selectedModel;

  /// 日志列表
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  AIImageProvider() {
    // 设置日志回调
    _geminiService.onLog = _addLog;
  }

  /// 初始化 Gemini 服务
  void initializeGemini(String apiKey) {
    _geminiService.initialize(apiKey);
  }

  /// 添加日志
  void _addLog(LogEntry entry) {
    _logs.add(entry);
    notifyListeners();
  }

  /// 清除日志
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// 设置图片
  Future<void> setImage(Uint8List data, {String? name, String? path}) async {
    _originalData = data;
    _fileName = name;
    _filePath = path;
    _resultData = null;
    _errorMessage = null;
    _status = AIImageStatus.idle;

    // 解码获取原始尺寸
    try {
      final codec = await instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      _originalSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
    } catch (e) {
      _originalSize = null;
    }

    _addLog(
      LogEntry(type: LogType.info, message: '已加载图片: ${name ?? "unknown"}'),
    );

    notifyListeners();
  }

  /// 设置提示词
  void setPrompt(String value) {
    _prompt = value;
    notifyListeners();
  }

  /// 设置宽高比
  void setAspectRatio(String value) {
    _aspectRatio = value;
    notifyListeners();
  }

  /// 设置分辨率
  void setResolution(String value) {
    _resolution = value;
    notifyListeners();
  }

  /// 设置模型
  void setModel(GeminiModel model) {
    _selectedModel = model;
    notifyListeners();
  }

  /// 生成图片
  Future<void> generate() async {
    if (_originalData == null) {
      _errorMessage = '请先上传图片';
      notifyListeners();
      return;
    }

    if (_prompt.isEmpty) {
      _errorMessage = '请输入提示词';
      notifyListeners();
      return;
    }

    if (!_geminiService.isInitialized) {
      _errorMessage = '请先在设置中配置 Gemini API Key';
      notifyListeners();
      return;
    }

    _status = AIImageStatus.processing;
    _errorMessage = null;
    _resultData = null;
    notifyListeners();

    try {
      // 宽高比：如果是"自适应"则传 null
      final aspectRatioValue = _aspectRatio == '自适应' ? null : _aspectRatio;

      final result = await _geminiService.editImage(
        imageData: _originalData!,
        prompt: _prompt,
        modelId: _selectedModel.id,
        aspectRatio: aspectRatioValue,
        resolution: _resolution,
      );

      if (result.success && result.imageData != null) {
        _resultData = result.imageData;
        _status = AIImageStatus.success;
      } else {
        _errorMessage = result.error ?? '生成失败';
        _status = AIImageStatus.error;
      }
    } catch (e) {
      _errorMessage = '处理失败: $e';
      _status = AIImageStatus.error;
      _addLog(LogEntry(type: LogType.error, message: _errorMessage!));
    }

    notifyListeners();
  }

  /// 清除结果
  void clearResult() {
    _resultData = null;
    _status = AIImageStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// 完全重置
  void reset() {
    _originalData = null;
    _resultData = null;
    _fileName = null;
    _filePath = null;
    _originalSize = null;
    _status = AIImageStatus.idle;
    _errorMessage = null;
    _prompt = '';
    _aspectRatio = '自适应';
    _resolution = '1K';
    _selectedModel = GeminiModel.defaultModel;
    _logs.clear();
    notifyListeners();
  }

  /// 导出状态
  Future<Map<String, dynamic>> exportState() async {
    String? originalPath = _filePath;
    if (originalPath == null && _originalData != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_ai_origin_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_originalData!);
        originalPath = file.path;
      } catch (e) {
        debugPrint('Failed to save temp original image: $e');
      }
    }

    String? resultPath;
    if (_resultData != null) {
      try {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/pictools_ai_result_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(_resultData!);
        resultPath = file.path;
      } catch (e) {
        debugPrint('Failed to save temp result image: $e');
      }
    }

    return {
      'filePath': originalPath,
      'resultPath': resultPath,
      'fileName': _fileName,
      'prompt': _prompt,
      'aspectRatio': _aspectRatio,
      'resolution': _resolution,
      'modelId': _selectedModel.id,
      'logs': _logs
          .map((e) => {'type': e.type.index, 'message': e.message})
          .toList(),
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

    if (state['resultPath'] != null) {
      final path = state['resultPath'] as String;
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _resultData = bytes;
          _status = AIImageStatus.success;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Failed to load result image: $e');
      }
    }

    if (state['prompt'] != null) {
      _prompt = state['prompt'];
    }

    if (state['aspectRatio'] != null) {
      _aspectRatio = state['aspectRatio'];
    }

    if (state['resolution'] != null) {
      _resolution = state['resolution'];
    }

    if (state['modelId'] != null) {
      try {
        _selectedModel = GeminiModel.available.firstWhere(
          (m) => m.id == state['modelId'],
          orElse: () => GeminiModel.defaultModel,
        );
      } catch (_) {
        _selectedModel = GeminiModel.defaultModel;
      }
    }

    if (state['logs'] != null) {
      final List logsList = state['logs'];
      _logs.clear();
      _logs.addAll(
        logsList.map(
          (e) =>
              LogEntry(type: LogType.values[e['type']], message: e['message']),
        ),
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _geminiService.dispose();
    super.dispose();
  }
}
