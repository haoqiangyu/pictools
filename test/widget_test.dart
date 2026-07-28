// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictools/main.dart';
import 'package:pictools/l10n/app_localizations.dart';
import 'package:pictools/services/settings_provider.dart';
import 'package:pictools/services/window_arguments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    // Create settings provider for test
    final settingsProvider = SettingsProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      PictoolsApp(
        settingsProvider: settingsProvider,
        windowArgs: const WindowArguments(type: WindowType.main),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Pictools'), findsOneWidget);
  });

  testWidgets('selected language updates the complete home screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settingsProvider = SettingsProvider();
    await settingsProvider.setLanguage('es');

    await tester.pumpWidget(
      PictoolsApp(
        settingsProvider: settingsProvider,
        windowArgs: const WindowArguments(type: WindowType.main),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Herramientas para imágenes'), findsOneWidget);
    expect(find.text('Comparar imágenes'), findsOneWidget);
    expect(find.text('Mejorar brillo'), findsOneWidget);
    expect(
      AppLocalizations(const Locale('es')).toolName('image_converter'),
      'Convertir formato',
    );
  });

  test(
    'locale resolution supports traditional Chinese and Chinese fallback',
    () {
      expect(
        AppLocalizations.resolveLocale(const [
          Locale('zh', 'TW'),
        ], AppLocalizations.supportedLocales).scriptCode,
        'Hant',
      );
      expect(
        AppLocalizations.resolveLocale(const [
          Locale('ja'),
        ], AppLocalizations.supportedLocales),
        const Locale('zh', 'CN'),
      );
    },
  );
}
