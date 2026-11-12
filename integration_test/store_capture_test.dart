// Store artwork source capture. Uses the production app and real processing.
// Fixtures are copied to the application's Documents/store-fixtures directory
// by scripts/store/capture_ios.py before running this target.
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pictools/main.dart';
import 'package:pictools/l10n/studio_localizations.dart';
import 'package:pictools/widgets/studio_widgets.dart' show ImageSourceSheet;
import 'package:pictools/models/adjust_mode.dart';
import 'package:pictools/models/aspect_ratio.dart';
import 'package:pictools/models/export_format.dart';
import 'package:pictools/models/export_options.dart';
import 'package:pictools/providers/image_adjust_provider.dart';
import 'package:pictools/providers/image_compare_provider.dart';
import 'package:pictools/providers/image_enhance_provider.dart';
import 'package:pictools/providers/batch_converter_provider.dart';
import 'package:pictools/screens/home_screen.dart';
import 'package:pictools/services/image_import_service.dart';
import 'package:pictools/services/image_processing_service.dart';
import 'package:pictools/services/settings_provider.dart';
import 'package:pictools/services/window_arguments.dart';
import 'package:pictools/src/rust/frb_generated.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture current Pictools store screens', (tester) async {
    if (const bool.fromEnvironment('STORE_LANDSCAPE')) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    await RustLib.init();
    final documents = await getApplicationDocumentsDirectory();
    final fixtures = Directory('${documents.path}/store-fixtures');
    final coast = await File('${fixtures.path}/coast.png').readAsBytes();
    final stillLife = await File(
      '${fixtures.path}/still-life.png',
    ).readAsBytes();
    const languages = {
      'zh-CN': 'zh_CN',
      'zh-TW': 'zh_TW',
      'en-US': 'en',
      'es-ES': 'es',
      'fr-FR': 'fr',
      'de-DE': 'de',
    };
    const fileNames = {
      'zh-CN': ['海岸漫步', '午后静物', '海边小巷'],
      'zh-TW': ['海岸漫步', '午後靜物', '海邊小巷'],
      'en-US': ['Coastal walk', 'Afternoon still life', 'Seaside lane'],
      'es-ES': ['Paseo costero', 'Naturaleza muerta', 'Calle junto al mar'],
      'fr-FR': ['Balade côtière', 'Nature morte', 'Ruelle en bord de mer'],
      'de-DE': ['Küstenspaziergang', 'Stillleben', 'Gasse am Meer'],
    };
    final locales = const String.fromEnvironment(
      'STORE_LOCALES',
      defaultValue: 'zh-CN,zh-TW,en-US,es-ES,fr-FR,de-DE',
    ).split(',');
    var surfaceConverted = false;
    for (final locale in locales) {
      const importsOnly = bool.fromEnvironment('STORE_ONLY_IMPORT');
      final output = Directory(
        '${documents.path}/${importsOnly ? 'store-import-captures' : 'store-captures'}/$locale',
      );
      await output.create(recursive: true);
      final names = fileNames[locale]!;
      final settings = SettingsProvider();
      await settings.setLanguage(languages[locale]!);
      await settings.setThemeMode(ThemeMode.light);
      await tester.pumpWidget(
        KeyedSubtree(
          key: UniqueKey(),
          child: PictoolsApp(
            settingsProvider: settings,
            windowArgs: const WindowArguments(type: WindowType.main),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await File('${output.path}/device.json').writeAsString(
        jsonEncode({
          'platform': Platform.operatingSystem,
          'locale': locale,
          'width': tester.view.physicalSize.width,
          'height': tester.view.physicalSize.height,
          'pixelRatio': tester.view.devicePixelRatio,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (Platform.isAndroid && !surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
        await tester.pumpAndSettle();
      }
      final context = tester.element(find.byType(HomeScreen));
      final navigator = Navigator.of(context);
      final adjust = context.read<ImageAdjustProvider>();
      final compare = context.read<ImageCompareProvider>();
      final enhance = context.read<ImageEnhanceProvider>();
      final batch = context.read<BatchConverterProvider>();

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 450));
        final bytes = await binding.takeScreenshot(name);
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        binding.reportData?.remove('screenshots');
        debugPrint('STORE_CAPTURE $locale $name');
      }

      Future<void> route(String name) async {
        navigator.pushNamed(name);
        await tester.pumpAndSettle();
      }

      if (!importsOnly) {
        await shot('home');
        await adjust.setImage(coast, name: '${names[0]}.png');
        adjust.setMode(AdjustMode.crop);
        adjust.setAspectRatio(AspectRatioPreset.ratio4x3);
        await route('/image-adjust');
        await shot('crop');

        adjust.setMode(AdjustMode.resize);
        adjust.setTargetWidth(1200);
        await shot('resize');

        // The comparison and enhancement show genuine output from the same
        // processing service used in the release app, not a fabricated result.
        await enhance.setImage(coast, name: '${names[0]}.png');
        await enhance.enhance();
        expect(enhance.hasEnhanced, isTrue);
        compare.setImageA(coast, name: '${names[0]}.png');
        compare.setImageB(
          enhance.enhancedData!,
          name: '${names[0]}_enhanced.png',
        );
        await route('/image-compare');
        await shot('compare');
        await route('/image-enhance');
        await shot('enhance');

        final detail = await ImageProcessingService.export(
          coast,
          const ExportOptions(format: ExportFormat.png),
          crop: [0.45, 0.05, 0.5, 0.85],
        );
        batch.add(
          ImportedImage(coast, '${names[0]}.png', width: 1536, height: 1024),
        );
        batch.add(
          ImportedImage(
            stillLife,
            '${names[1]}.png',
            width: 1024,
            height: 1024,
          ),
        );
        batch.add(
          ImportedImage(detail, '${names[2]}.png', width: 768, height: 870),
        );
        batch.setOptions(
          const ExportOptions(format: ExportFormat.jpg, quality: 90),
        );
        await batch.run();
        expect(batch.complete, 3);
        await route('/image-converter');
        await shot('batch');

        adjust.setMode(AdjustMode.crop);
        await route('/image-adjust');
        final export = find.text(context.s('exportImage'));
        await tester.tap(
          export.evaluate().isNotEmpty
              ? export.last
              : find.byTooltip(context.s('exportImage')).last,
        );
        await tester.pumpAndSettle();
        expect(find.text(context.s('saveToPhotos')), findsOneWidget);
        expect(find.text(context.s('saveToFiles')), findsOneWidget);
        await shot('export');
        await tester.tap(find.byTooltip(context.s('close')).last);
        await tester.pumpAndSettle();

        await settings.setThemeMode(ThemeMode.dark);
        await shot('dark');
        await settings.setThemeMode(ThemeMode.light);
        await route('/');
      }
      await tester.tap(find.text(context.s('selectImage')).first);
      await tester.pump();
      await tester.pump();
      final chooserContext = tester.element(find.text(context.s('importFrom')));
      final chooserRoute = ModalRoute.of(chooserContext)!;
      for (
        var frame = 0;
        frame < 20 &&
            chooserRoute.animation!.status != AnimationStatus.completed;
        frame++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(chooserRoute.animation!.status, AnimationStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await tester.pump();
      // Import chooser can leave the triggering button busy until it closes.
      final bytes = await binding.takeScreenshot('import');
      final dialogRect = tester.getRect(find.byType(ImageSourceSheet).last);
      final bitmap = img.decodePng(Uint8List.fromList(bytes))!;
      final pixel = bitmap.getPixel(
        (dialogRect.center.dx * tester.view.devicePixelRatio).round(),
        ((dialogRect.top + 12) * tester.view.devicePixelRatio).round(),
      );
      expect(
        pixel.rNormalized * 255,
        closeTo(247, 3),
        reason: 'Dialog must be opaque before capture',
      );
      expect(pixel.gNormalized * 255, closeTo(246, 3));
      expect(pixel.bNormalized * 255, closeTo(242, 3));
      await File('${output.path}/import.png').writeAsBytes(bytes);
      binding.reportData?.remove('screenshots');
      expect(find.text(context.s('photoLibrary')), findsOneWidget);
      expect(find.text(context.s('files')), findsOneWidget);
      debugPrint('STORE_CAPTURE $locale import');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      settings.dispose();
    }
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  });
}
