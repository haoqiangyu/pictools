import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// 设置状态管理 Provider
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String? _geminiApiKey;
  bool _isLoading = false;
  String? _errorMessage;

  /// 获取 Gemini API Key
  String? get geminiApiKey => _geminiApiKey;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 是否已配置 API Key
  bool get hasApiKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;

  /// 初始化 - 加载存储的设置
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _geminiApiKey = await _service.getGeminiApiKey();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载设置失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存 Gemini API Key
  Future<bool> saveGeminiApiKey(String? key) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setGeminiApiKey(key);
      _geminiApiKey = key;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '保存 API Key 失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除 API Key
  Future<void> clearApiKey() async {
    await saveGeminiApiKey(null);
  }

  /// 验证 API Key 格式 (简单检查)
  bool isValidApiKeyFormat(String? key) {
    if (key == null || key.isEmpty) return false;
    // Gemini API Key 通常以 'AI' 开头，长度约 39 字符
    return key.length >= 30;
  }
}
