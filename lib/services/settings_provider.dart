import 'package:flutter/material.dart';

import 'settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String? _language;

  String? get language => _language;

  Locale? get locale {
    return switch (_language) {
      'zh_CN' => const Locale('zh', 'CN'),
      'zh_TW' => const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      ),
      'en' => const Locale('en'),
      'es' => const Locale('es'),
      'fr' => const Locale('fr'),
      'de' => const Locale('de'),
      _ => null,
    };
  }

  Future<void> init() async {
    _language = await _service.getLanguage();
  }

  Future<void> setLanguage(String? language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await _service.setLanguage(language);
  }
}
