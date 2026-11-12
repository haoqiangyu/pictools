import 'package:pictools/services/photo_library_service.dart';
import 'package:pictools/layout/foldable_environment.dart';
import 'package:pictools/screens/image_adjust_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;
import 'package:pictools/main.dart';
import 'package:pictools/models/export_format.dart';
import 'package:pictools/models/export_options.dart';
import 'package:pictools/services/image_processing_service.dart';
import 'package:pictools/services/settings_provider.dart';
import 'package:pictools/services/window_arguments.dart';
import 'package:pictools/src/rust/frb_generated.dart';
import 'package:pictools/screens/home_screen.dart';
import 'package:pictools/providers/image_adjust_provider.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native codecs, enhancement and editor navigation work', (
    tester,
  ) async {
    await RustLib.init();
    final settings = SettingsProvider();
    await settings.setLanguage('zh_CN');
    await tester.pumpWidget(
      PictoolsApp(
        settingsProvider: settings,
        windowArgs: const WindowArguments(type: WindowType.main),
      ),
    );
    await tester.pumpAndSettle();
    final image = img.Image(width: 128, height: 96, numChannels: 4);
    for (final pixel in image) {
      pixel.setRgba(
        (pixel.x * 7 + pixel.y * 3) % 256,
        (pixel.x * 3 + pixel.y * 7) % 256,
        (pixel.x * 13) % 256,
        255,
      );
    }
    final source = img.encodePng(image);
    for (final format in ExportFormat.values) {
      final output = await ImageProcessingService.export(
        source,
        ExportOptions(format: format, lossless: true),
      );
      final result = img.decodeImage(output)!;
      expect((result.width, result.height), (128, 96), reason: format.name);
    }
    if (const bool.fromEnvironment('TEST_PHOTOS_EXPORT')) {
      await PhotoLibraryService.ensurePermission();
      for (final format in [ExportFormat.png, ExportFormat.jpg]) {
        final bytes = await ImageProcessingService.export(
          source,
          ExportOptions(format: format),
        );
        await PhotoLibraryService.save(
          bytes: bytes,
          fileName: 'pictools-save-qa.${format.extension}',
          format: format,
        );
      }
    }
    final low = await ImageProcessingService.export(
      source,
      const ExportOptions(format: ExportFormat.jpg, quality: 15),
    );
    final high = await ImageProcessingService.export(
      source,
      const ExportOptions(format: ExportFormat.jpg, quality: 95),
    );
    expect(high.length, greaterThan(low.length));
    final webp = img.decodeWebP(
      await ImageProcessingService.export(
        source,
        const ExportOptions(format: ExportFormat.webp, lossless: true),
      ),
    )!;
    expect(webp.getPixel(20, 20).r, image.getPixel(20, 20).r);
    final enhanced = img.decodePng(
      await ImageProcessingService.enhance(source),
    )!;
    expect(enhanced.width, 128);
    expect(enhanced.getPixel(3, 3).r, greaterThan(image.getPixel(3, 3).r));
    final context = tester.element(find.byType(HomeScreen));
    await context.read<ImageAdjustProvider>().setImage(
      source,
      name: 'native-smoke.png',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('裁剪与尺寸').first);
    await tester.pumpAndSettle();
    expect(find.text('导出图片'), findsOneWidget);
    await tester.tap(find.text('导出图片'));
    await tester.pumpAndSettle();
    expect(find.text('保存到文件'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('导出图片'), findsOneWidget);
    // Geometry is supplied by the actual iOS Flutter view, not a device fixture.
    final geometry = FoldableEnvironment.of(
      tester.element(find.byType(ImageAdjustScreen)),
    );
    expect(geometry.windowSize.width, greaterThan(0));
    expect(geometry.windowSize.height, greaterThan(0));
  });
}
