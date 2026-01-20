import 'package:shared_preferences/shared_preferences.dart';

/// 设置持久化服务
/// 用于存储和读取应用配置，如 API Key 等
class SettingsService {
  static const _keyGeminiApiKey = 'gemini_api_key';

  SharedPreferences? _prefs;

  /// 初始化服务
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 获取 Gemini API Key
  Future<String?> getGeminiApiKey() async {
    await init();
    return _prefs?.getString(_keyGeminiApiKey);
  }

  /// 设置 Gemini API Key
  Future<void> setGeminiApiKey(String? key) async {
    await init();
    if (key == null || key.isEmpty) {
      await _prefs?.remove(_keyGeminiApiKey);
    } else {
      await _prefs?.setString(_keyGeminiApiKey, key);
    }
  }

  /// 检查是否已配置 Gemini API Key
  Future<bool> hasGeminiApiKey() async {
    final key = await getGeminiApiKey();
    return key != null && key.isNotEmpty;
  }

  /// 清除所有设置
  Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
  }
}
