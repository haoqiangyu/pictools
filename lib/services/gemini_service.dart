import 'dart:convert';
import 'dart:typed_data';
import 'package:googleai_dart/googleai_dart.dart';

/// 日志条目类型
enum LogType { info, request, response, error }

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;

  LogEntry({required this.type, required this.message})
    : timestamp = DateTime.now();
}

/// Gemini API 调用结果
class GeminiResult {
  final Uint8List? imageData;
  final String? text;
  final String? error;
  final bool success;

  GeminiResult({this.imageData, this.text, this.error, required this.success});

  factory GeminiResult.success({Uint8List? imageData, String? text}) {
    return GeminiResult(imageData: imageData, text: text, success: true);
  }

  factory GeminiResult.failure(String error) {
    return GeminiResult(error: error, success: false);
  }
}

/// 模型定义
class GeminiModel {
  final String id;
  final String alias;
  final String displayName;

  const GeminiModel({
    required this.id,
    required this.alias,
    required this.displayName,
  });

  /// 可用模型列表
  static const List<GeminiModel> available = [
    GeminiModel(
      id: 'gemini-3-pro-image-preview',
      alias: 'NanoBanana Pro',
      displayName: 'NanoBanana Pro (gemini-3-pro-image-preview)',
    ),
    GeminiModel(
      id: 'gemini-2.5-flash-image',
      alias: 'NanoBanana',
      displayName: 'NanoBanana (gemini-2.5-flash-image)',
    ),
  ];

  static GeminiModel get defaultModel => available.first;
}

/// Gemini API 服务封装
class GeminiService {
  GoogleAIClient? _client;
  String? _apiKey;

  /// 日志回调
  void Function(LogEntry)? onLog;

  /// 是否已初始化
  bool get isInitialized => _client != null && _apiKey != null;

  /// 初始化客户端
  void initialize(String apiKey) {
    _apiKey = apiKey;
    _client = GoogleAIClient(
      config: GoogleAIConfig(authProvider: ApiKeyProvider(apiKey)),
    );
    _log(LogType.info, 'Gemini 客户端已初始化');
  }

  /// 释放资源
  void dispose() {
    _client?.close();
    _client = null;
    _apiKey = null;
  }

  /// 记录日志
  void _log(LogType type, String message) {
    onLog?.call(LogEntry(type: type, message: message));
  }

  /// 使用 Gemini 修改图片
  ///
  /// [imageData] - 原始图片数据
  /// [prompt] - 用户提示词
  /// [modelId] - 模型 ID
  /// [aspectRatio] - 目标宽高比 (可选，null 表示自适应)
  /// [resolution] - 目标分辨率
  Future<GeminiResult> editImage({
    required Uint8List imageData,
    required String prompt,
    required String modelId,
    String? aspectRatio,
    String resolution = '1K',
  }) async {
    if (_client == null) {
      const error = '客户端未初始化，请先设置 API Key';
      _log(LogType.error, error);
      return GeminiResult.failure(error);
    }

    try {
      // 构建完整的提示词
      final StringBuffer promptBuffer = StringBuffer();
      promptBuffer.writeln(
        'Edit this image according to the following instructions:',
      );
      promptBuffer.writeln(prompt);
      promptBuffer.writeln();
      promptBuffer.writeln('Output requirements:');
      if (aspectRatio != null && aspectRatio.isNotEmpty) {
        promptBuffer.writeln('- Aspect ratio: $aspectRatio');
      }
      promptBuffer.writeln('- Resolution: $resolution');

      final fullPrompt = promptBuffer.toString();

      _log(
        LogType.request,
        '模型: $modelId\n提示词: $prompt\n宽高比: ${aspectRatio ?? "自适应"}\n分辨率: $resolution',
      );

      // 将图片转为 base64
      final imageBase64 = base64Encode(imageData);

      // 检测图片 MIME 类型
      final mimeType = _detectMimeType(imageData);
      _log(
        LogType.info,
        '图片格式: $mimeType, 大小: ${(imageData.length / 1024).toStringAsFixed(1)} KB',
      );

      // 发送请求
      final response = await _client!.models.generateContent(
        model: modelId,
        request: GenerateContentRequest(
          contents: [
            Content(
              parts: [
                TextPart(fullPrompt),
                InlineDataPart(Blob(mimeType: mimeType, data: imageBase64)),
              ],
            ),
          ],
          generationConfig: GenerationConfig(
            responseModalities: ['TEXT', 'IMAGE'],
            imageConfig: ImageConfig(
              aspectRatio: aspectRatio,
              imageSize: resolution,
            ),
          ),
        ),
      );

      // 解析响应
      return _parseResponse(response);
    } catch (e) {
      final error = '请求失败: $e';
      _log(LogType.error, error);
      return GeminiResult.failure(error);
    }
  }

  /// 解析 API 响应
  GeminiResult _parseResponse(GenerateContentResponse response) {
    Uint8List? imageData;
    String? textContent;

    // 遍历所有候选响应
    for (final candidate in response.candidates ?? []) {
      for (final part in candidate.content?.parts ?? []) {
        // 处理文本部分
        if (part is TextPart) {
          textContent = (textContent ?? '') + part.text;
        }

        // 处理图片部分
        if (part is InlineDataPart) {
          final blob = part.inlineData;
          if (blob.data != null) {
            try {
              imageData = base64Decode(blob.data!);
              _log(
                LogType.response,
                '收到图片响应, 大小: ${(imageData.length / 1024).toStringAsFixed(1)} KB',
              );
            } catch (e) {
              _log(LogType.error, '解码图片数据失败: $e');
            }
          }
        }
      }
    }

    if (textContent != null) {
      _log(LogType.response, '文本响应: $textContent');
    }

    if (imageData != null) {
      return GeminiResult.success(imageData: imageData, text: textContent);
    } else if (textContent != null) {
      _log(LogType.info, '未收到图片，仅收到文本响应');
      return GeminiResult.failure('未生成图片: $textContent');
    } else {
      return GeminiResult.failure('API 响应为空');
    }
  }

  /// 检测图片 MIME 类型
  String _detectMimeType(Uint8List data) {
    if (data.length < 4) return 'image/jpeg';

    // PNG: 89 50 4E 47
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'image/png';
    }
    // JPEG: FF D8 FF
    if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
      return 'image/jpeg';
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46) {
      if (data.length >= 12 &&
          data[8] == 0x57 &&
          data[9] == 0x45 &&
          data[10] == 0x42 &&
          data[11] == 0x50) {
        return 'image/webp';
      }
    }
    // GIF: 47 49 46 38
    if (data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }
}
