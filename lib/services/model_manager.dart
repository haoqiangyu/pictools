import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RMBG-2.0模型精度类型
enum ModelPrecision {
  full('model.onnx', 'RMBG-2.0 Full', 1095 * 1024 * 1024), // ~1.02GB
  fp16('model_fp16.onnx', 'RMBG-2.0 FP16', 514 * 1024 * 1024), // ~514MB
  int8('model_int8.onnx', 'RMBG-2.0 INT8', 366 * 1024 * 1024); // ~366MB

  const ModelPrecision(this.fileName, this.displayName, this.approximateSize);

  final String fileName;
  final String displayName;
  final int approximateSize;

  String get downloadUrl {
    switch (this) {
      case ModelPrecision.full:
        return 'https://huggingface.co/briaai/RMBG-2.0/resolve/main/onnx/model.onnx?download=true';
      case ModelPrecision.fp16:
        return 'https://huggingface.co/briaai/RMBG-2.0/resolve/main/onnx/model_fp16.onnx?download=true';
      case ModelPrecision.int8:
        return 'https://huggingface.co/briaai/RMBG-2.0/resolve/main/onnx/model_int8.onnx';
    }
  }
}

/// 模型下载进度信息
class DownloadProgress {
  final int received;
  final int total;
  final double speed; // bytes per second

  DownloadProgress({
    required this.received,
    required this.total,
    required this.speed,
  });

  double get percentage => total > 0 ? (received / total) * 100 : 0;

  String get receivedMB => (received / (1024 * 1024)).toStringAsFixed(2);
  String get totalMB => (total / (1024 * 1024)).toStringAsFixed(2);
  String get speedMBps => (speed / (1024 * 1024)).toStringAsFixed(2);
}

/// 模型信息
class ModelInfo {
  final ModelPrecision precision;
  final String path;
  final int size;
  final DateTime downloadedAt;

  ModelInfo({
    required this.precision,
    required this.path,
    required this.size,
    required this.downloadedAt,
  });

  String get sizeMB => (size / (1024 * 1024)).toStringAsFixed(2);
}

/// 模型管理服务
class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  static const String _customPathKey = 'model_storage_path';
  static const String _hfTokenKey = 'huggingface_token';
  String? _customStoragePath;
  String? _huggingFaceToken;
  CancelToken? _cancelToken;
  int _lastReceivedBytes = 0;
  DateTime _lastProgressTime = DateTime.now();

  /// 获取模型存储目录
  Future<Directory> getModelDirectory() async {
    if (_customStoragePath != null && _customStoragePath!.isNotEmpty) {
      return Directory(_customStoragePath!);
    }

    final appSupport = await getApplicationSupportDirectory();
    return Directory('${appSupport.path}/models');
  }

  /// 设置自定义存储路径
  Future<void> setCustomStoragePath(String? path) async {
    _customStoragePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString(_customPathKey, path);
    } else {
      await prefs.remove(_customPathKey);
    }
  }

  /// 加载自定义存储路径
  Future<void> loadCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    _customStoragePath = prefs.getString(_customPathKey);
  }

  /// 设置HuggingFace Token
  Future<void> setHuggingFaceToken(String? token) async {
    _huggingFaceToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_hfTokenKey, token);
    } else {
      await prefs.remove(_hfTokenKey);
    }
  }

  /// 加载HuggingFace Token
  Future<void> loadHuggingFaceToken() async {
    final prefs = await SharedPreferences.getInstance();
    _huggingFaceToken = prefs.getString(_hfTokenKey);
  }

  /// 获取当前的HuggingFace Token
  String? get huggingFaceToken => _huggingFaceToken;

  /// 获取模型文件路径
  Future<String> getModelPath(ModelPrecision precision) async {
    final dir = await getModelDirectory();
    return '${dir.path}/${precision.fileName}';
  }

  /// 检查模型是否已下载
  Future<bool> isModelDownloaded(ModelPrecision precision) async {
    final path = await getModelPath(precision);
    final file = File(path);
    return file.existsSync() && await file.length() > 0;
  }

  /// 获取已下载的模型信息
  Future<ModelInfo?> getModelInfo(ModelPrecision precision) async {
    if (!await isModelDownloaded(precision)) {
      return null;
    }

    final path = await getModelPath(precision);
    final file = File(path);
    final stat = await file.stat();

    return ModelInfo(
      precision: precision,
      path: path,
      size: stat.size,
      downloadedAt: stat.modified,
    );
  }

  /// 获取所有已下载的模型
  Future<List<ModelInfo>> getAllDownloadedModels() async {
    final models = <ModelInfo>[];
    for (final precision in ModelPrecision.values) {
      final info = await getModelInfo(precision);
      if (info != null) {
        models.add(info);
      }
    }
    return models;
  }

  /// 下载模型
  ///
  /// [precision] - 模型精度
  /// [onProgress] - 进度回调
  /// 返回下载后的文件路径
  Future<String> downloadModel(
    ModelPrecision precision, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    final dir = await getModelDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final savePath = await getModelPath(precision);
    final tempPath = '$savePath.tmp';

    // 检查是否有未完成的下载（断点续传）
    final tempFile = File(tempPath);
    int downloadedBytes = 0;
    if (tempFile.existsSync()) {
      downloadedBytes = await tempFile.length();
    }

    _cancelToken = CancelToken();
    _lastReceivedBytes = downloadedBytes;
    _lastProgressTime = DateTime.now();

    final dio = Dio();

    try {
      // 准备请求头
      final headers = <String, String>{};
      if (_huggingFaceToken != null && _huggingFaceToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_huggingFaceToken';
      }
      if (downloadedBytes > 0) {
        headers['Range'] = 'bytes=$downloadedBytes-';
      }

      await dio.download(
        precision.downloadUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            final now = DateTime.now();
            final timeDiff =
                now.difference(_lastProgressTime).inMilliseconds / 1000.0;
            final bytesDiff = received - _lastReceivedBytes;
            final speed = timeDiff > 0
                ? (bytesDiff / timeDiff).toDouble()
                : 0.0;

            onProgress(
              DownloadProgress(received: received, total: total, speed: speed),
            );

            _lastReceivedBytes = received;
            _lastProgressTime = now;
          }
        },
        cancelToken: _cancelToken,
        deleteOnError: false, // 保留部分下载的文件以支持断点续传
        options: Options(
          headers: headers.isNotEmpty ? headers : null,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      // 下载完成，重命名临时文件
      await tempFile.rename(savePath);
      return savePath;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('下载已取消');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('下载超时，请检查网络连接');
      } else {
        throw Exception('下载失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('下载失败: $e');
    }
  }

  /// 取消当前下载
  void cancelDownload() {
    _cancelToken?.cancel('用户取消下载');
  }

  /// 删除模型
  Future<void> deleteModel(ModelPrecision precision) async {
    final path = await getModelPath(precision);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }

    // 同时删除可能的临时文件
    final tempFile = File('$path.tmp');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
  }

  /// 获取模型目录的总大小
  Future<int> getTotalModelSize() async {
    int totalSize = 0;
    for (final precision in ModelPrecision.values) {
      final info = await getModelInfo(precision);
      if (info != null) {
        totalSize += info.size;
      }
    }
    return totalSize;
  }
}
