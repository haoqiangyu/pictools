import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  Future<String?> getThemeMode() async =>
      (await SharedPreferences.getInstance()).getString('themeMode');
  Future<void> setThemeMode(String value) async {
    await (await SharedPreferences.getInstance()).setString('themeMode', value);
  }

  static const _keyLanguage = 'language';

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  Future<void> setLanguage(String? language) async {
    final prefs = await SharedPreferences.getInstance();
    if (language == null) {
      await prefs.remove(_keyLanguage);
    } else {
      await prefs.setString(_keyLanguage, language);
    }
  }
}
