import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pictools/layout/foldable_environment.dart';
import 'package:pictools/l10n/app_localizations.dart';
import 'package:pictools/models/adjust_mode.dart';
import 'package:pictools/models/aspect_ratio.dart';
import 'package:pictools/providers/image_adjust_provider.dart';
import 'package:pictools/providers/image_compare_provider.dart';
import 'package:pictools/providers/image_enhance_provider.dart';
import 'package:pictools/providers/batch_converter_provider.dart';
import 'package:pictools/screens/home_screen.dart';
import 'package:pictools/screens/image_adjust_screen.dart';
import 'package:pictools/screens/image_compare_screen.dart';
import 'package:pictools/screens/image_enhance_screen.dart';
import 'package:pictools/screens/image_converter_screen.dart';
import 'package:pictools/screens/settings_screen.dart';
import 'package:pictools/services/settings_provider.dart';
import 'package:pictools/services/image_import_service.dart';
import 'package:pictools/theme/app_theme.dart';
import 'package:pictools/widgets/studio_canvas.dart';
import 'package:pictools/widgets/crop_overlay.dart';
import 'package:pictools/widgets/export_sheet.dart';
import 'package:pictools/widgets/studio_widgets.dart';

ThemeData _qaTheme(bool dark) {
  final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return captures
      ? theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'StudioQA'))
      : theme;
}

final boundary = GlobalKey();
const captures = bool.fromEnvironment('STUDIO_CAPTURE');

class Rig {
  final adjust = ImageAdjustProvider(),
      compare = ImageCompareProvider(),
      enhance = ImageEnhanceProvider(),
      batch = BatchConverterProvider(),
      settings = SettingsProvider();
  Widget build(
    Widget screen, {
    Size size = const Size(390, 844),
    EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
    double scale = 1,
    double keyboard = 0,
    Locale locale = const Locale('zh', 'CN'),
    bool dark = false,
    List<Rect> folds = const [],
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: adjust),
      ChangeNotifierProvider.value(value: compare),
      ChangeNotifierProvider.value(value: enhance),
      ChangeNotifierProvider.value(value: batch),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      theme: _qaTheme(dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          padding: padding,
          viewPadding: padding,
          viewInsets: EdgeInsets.only(bottom: keyboard),
          textScaler: TextScaler.linear(scale),
        ),
        child: FoldableEnvironment(
          geometry: FoldableGeometry(windowSize: size, divisions: folds),
          child: RepaintBoundary(key: boundary, child: child!),
        ),
      ),
      home: screen,
    ),
  );
  Future<void> seed(WidgetTester t, Uint8List bytes) async {
    await t.runAsync(() async {
      await adjust.setImage(bytes, name: 'coast-study.png');
      await enhance.setImage(bytes, name: 'coast-study.png');
    });
    adjust.setAspectRatio(AspectRatioPreset.ratio4x3);
    compare.setImageA(bytes, name: 'coast-study.png');
    compare.setImageB(bytes, name: 'coast-copy.png');
    batch.add(
      ImportedImage(bytes, 'coast-study.png', width: 1536, height: 1024),
    );
  }

  void dispose() {
    adjust.dispose();
    compare.dispose();
    enhance.dispose();
    batch.dispose();
    settings.dispose();
  }
}

// The widget-test engine uses Ahem when a TextStyle omits a font family.
// Apply the same loaded CJK font to those render spans for human visual review.
// Geometry assertions run separately with the normal test font.
InlineSpan _reviewFont(InlineSpan span) {
  if (span is! TextSpan) return span;
  final family = span.style?.fontFamily;
  return TextSpan(
    text: span.text,
    style: (span.style ?? const TextStyle()).copyWith(
      fontFamily: family == 'MaterialIcons' ? family : 'StudioQA',
    ),
    children: span.children?.map(_reviewFont).toList(),
  );
}

void _reviewFonts(RenderObject object) {
  if (object is RenderParagraph) object.text = _reviewFont(object.text);
  object.visitChildren(_reviewFonts);
}

Future<void> capture(WidgetTester t, String name, {bool settle = true}) async {
  if (!captures ||
      !{
        'phone-home',
        'phone-crop',
        'phone-compare',
        'phone-enhance',
        'phone-batch',
        'phone-settings',
        'small-crop',
        'landscape-crop',
        'duo-inner-crop',
        'duo-left-crop',
        'book-crop',
        'tabletop-crop',
        'tabletop-keyboard-crop',
        'split-crop',
        'large-text-crop',
        'desktop-crop',
        'dark-crop',
        'dark-export',
        'rotated-export',
        'book-export',
        'phone-import-source',
        'book-import-source',
      }.contains(name)) {
    return;
  }
  await t.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final widget = element.widget as Image;
      await precacheImage(widget.image, element);
    }
  });
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
  _reviewFonts(boundary.currentContext!.findRenderObject()!);
  await t.pump();
  await t.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(
      pixelRatio: name == 'landscape-crop' ? 2 : 1,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('design-system/qa/flutter');
    await dir.create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List fixture;
  setUpAll(() async {
    fixture = await File('design-system/assets/coast-study.png').readAsBytes();
  });
  setUp(() async {
    if (captures) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final fontPath = Platform.environment['STUDIO_QA_FONT'];
      if (fontPath != null) {
        for (final family in ['StudioQA']) {
          final loader = FontLoader(family)
            ..addFont(
              File(fontPath).readAsBytes().then((b) => ByteData.sublistView(b)),
            );
          await loader.load();
        }
      }
    }
  });
  final geometries = <String, (Size, EdgeInsets, List<Rect>, double, double)>{
    'phone-360': (
      const Size(360, 740),
      const EdgeInsets.only(top: 24, bottom: 24),
      [],
      1,
      0,
    ),
    'phone-430': (
      const Size(430, 932),
      const EdgeInsets.only(top: 59, bottom: 34),
      [],
      1,
      0,
    ),
    'land-740': (
      const Size(740, 360),
      const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      [],
      1,
      0,
    ),
    'land-844': (
      const Size(844, 390),
      const EdgeInsets.only(left: 47, right: 47, bottom: 21),
      [],
      1,
      0,
    ),
    'land-932': (
      const Size(932, 430),
      const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      [],
      1,
      0,
    ),
    'tablet-768': (
      const Size(768, 1024),
      const EdgeInsets.only(top: 24, bottom: 20),
      [],
      1,
      0,
    ),
    'desktop-1366': (const Size(1366, 768), EdgeInsets.zero, [], 1, 0),
    'phone': (
      const Size(390, 844),
      const EdgeInsets.only(top: 47, bottom: 34),
      [],
      1,
      0,
    ),
    'small': (
      const Size(320, 568),
      const EdgeInsets.only(top: 20, bottom: 20),
      [],
      1,
      0,
    ),
    'landscape': (
      const Size(852, 393),
      const EdgeInsets.only(left: 44, right: 44, bottom: 21),
      [],
      1,
      0,
    ),
    'duo-outer': (
      const Size(466, 678),
      const EdgeInsets.only(top: 40, bottom: 24),
      [],
      1,
      0,
    ),
    'duo-inner': (
      const Size(951, 669),
      const EdgeInsets.only(right: 72),
      [],
      1,
      0,
    ),
    'duo-left': (
      const Size(951, 669),
      const EdgeInsets.only(left: 72),
      [],
      1,
      0,
    ),
    'duo-portrait': (
      const Size(669, 951),
      const EdgeInsets.only(top: 40, bottom: 24),
      [],
      1,
      0,
    ),
    'book': (
      const Size(951, 669),
      const EdgeInsets.only(right: 72),
      [const Rect.fromLTWH(450, 0, 32, 669)],
      1,
      0,
    ),
    'tabletop': (
      const Size(951, 669),
      const EdgeInsets.only(right: 72),
      [const Rect.fromLTWH(0, 310, 951, 48)],
      1,
      0,
    ),
    'tabletop-keyboard': (
      const Size(951, 669),
      const EdgeInsets.only(right: 72),
      [const Rect.fromLTWH(0, 310, 951, 48)],
      1,
      245,
    ),
    'split': (const Size(466, 669), const EdgeInsets.only(right: 24), [], 1, 0),
    'keyboard': (
      const Size(390, 844),
      const EdgeInsets.only(top: 47),
      [],
      1,
      320,
    ),
    'large-text': (
      const Size(390, 844),
      const EdgeInsets.only(top: 47, bottom: 34),
      [],
      2,
      0,
    ),
    'desktop': (const Size(1400, 900), EdgeInsets.zero, [], 1, 0),
  };
  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'crop': const ImageAdjustScreen(),
    'compare': const ImageCompareScreen(),
    'enhance': const ImageEnhanceScreen(),
    'batch': const ImageConverterScreen(),
    'settings': const SettingsScreen(),
  };
  for (final geometry in geometries.entries) {
    testWidgets('all tools fit ${geometry.key}', (t) async {
      final r = Rig();
      addTearDown(r.dispose);
      final (size, pad, folds, scale, kb) = geometry.value;
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await r.seed(t, fixture);
      for (final screen in screens.entries) {
        await t.pumpWidget(
          r.build(
            screen.value,
            size: size,
            padding: pad,
            folds: folds,
            scale: scale,
            keyboard: kb,
          ),
        );
        await t.pumpAndSettle();
        expect(
          t.takeException(),
          isNull,
          reason: '${screen.key} / ${geometry.key}',
        );
        if (geometry.key == 'keyboard' && screen.key == 'crop') {
          expect(find.byType(CropOverlay), findsNothing);
          expect(
            t.getSize(find.byType(StudioCanvas)).height,
            lessThanOrEqualTo(104),
          );
        }
        await capture(t, '${geometry.key}-${screen.key}');
      }
      await t.pumpWidget(const SizedBox());
    });
  }
  for (final size in [const Size(390, 844), const Size(951, 669)]) {
    testWidgets('import source visual layout $size', (t) async {
      final r = Rig();
      addTearDown(r.dispose);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final book = size.width > 600;
      await t.pumpWidget(
        r.build(
          const HomeScreen(),
          size: size,
          folds: book ? [const Rect.fromLTWH(450, 0, 32, 669)] : [],
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, '选择图片'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(find.byType(ImageSourceSheet), findsOneWidget);
      expect(t.takeException(), isNull);
      await capture(
        t,
        book ? 'book-import-source' : 'phone-import-source',
        settle: false,
      );
      await t.pumpWidget(const SizedBox());
    });
  }
  testWidgets('crop, text focus and export survive unfolding and rotation', (
    t,
  ) async {
    final r = Rig();
    addTearDown(r.dispose);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await r.seed(t, fixture);
    const screen = ImageAdjustScreen();
    final crop = r.adjust.cropRect;
    Future<void> pose(Size size, {List<Rect> folds = const []}) async {
      t.view.physicalSize = size;
      await t.pumpWidget(r.build(screen, size: size, folds: folds));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }

    await pose(const Size(390, 844));
    r.adjust.setMode(AdjustMode.resize);
    await t.pumpAndSettle();
    final width = find.byKey(const ValueKey('output-width'));
    await t.ensureVisible(width);
    await t.tap(width);
    await t.enterText(width, '1200');
    final editable = t.widget<EditableText>(
      find.descendant(of: width, matching: find.byType(EditableText)),
    );
    final focus = editable.focusNode;
    await pose(
      const Size(951, 669),
      folds: [const Rect.fromLTWH(450, 0, 32, 669)],
    );
    expect(r.adjust.targetWidth, 1200);
    expect(r.adjust.cropRect, crop);
    expect(focus.hasFocus, isTrue);
    expect(find.text('1200'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.tap(find.text('导出图片'));
    await t.pumpAndSettle();
    expect(find.byType(ExportSheet), findsOneWidget);
    final name = find.byType(TextField).last;
    await t.enterText(name, 'my-export');
    await capture(t, 'book-export');
    await pose(const Size(669, 951));
    expect(find.text('my-export'), findsOneWidget);
    await capture(t, 'rotated-export');
    await t.pumpWidget(const SizedBox());
  });
  for (final locale in [
    const Locale('en'),
    const Locale('es'),
    const Locale('fr'),
    const Locale('de'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ]) {
    testWidgets('large type in ${locale.toLanguageTag()}', (t) async {
      final r = Rig();
      addTearDown(r.dispose);
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await r.seed(t, fixture);
      for (final screen in screens.values) {
        await t.pumpWidget(
          r.build(screen, size: const Size(320, 568), scale: 2, locale: locale),
        );
        await t.pumpAndSettle();
        expect(
          t.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
      await t.pumpWidget(const SizedBox());
    });
  }
  testWidgets('comparison zoom and position survive fold transitions', (
    t,
  ) async {
    final r = Rig();
    addTearDown(r.dispose);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await r.seed(t, fixture);
    t.view.physicalSize = const Size(390, 844);
    await t.pumpWidget(r.build(const ImageCompareScreen()));
    await t.pumpAndSettle();
    final viewer = t.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    viewer.transformationController!.value = Matrix4.diagonal3Values(2, 2, 1)
      ..setTranslationRaw(-30, -20, 0);
    r.compare.setSliderPosition(.8);
    await t.pump();
    t.view.physicalSize = const Size(951, 669);
    await t.pumpWidget(
      r.build(
        const ImageCompareScreen(),
        size: const Size(951, 669),
        folds: [const Rect.fromLTWH(450, 0, 32, 669)],
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(r.compare.sliderPosition, .8);
    final unfolded = t.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      identical(
        viewer.transformationController,
        unfolded.transformationController,
      ),
      isTrue,
    );
    expect(unfolded.transformationController!.value.getMaxScaleOnAxis(), 2);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('dark editor and export keep contrast', (t) async {
    final r = Rig();
    addTearDown(r.dispose);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await r.seed(t, fixture);
    await t.pumpWidget(r.build(const ImageAdjustScreen(), dark: true));
    await t.pumpAndSettle();
    await capture(t, 'dark-crop');
    await t.tap(find.text('导出图片'));
    await t.pumpAndSettle();
    await capture(t, 'dark-export');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('book canvas stays outside reserved region', (t) async {
    final r = Rig();
    addTearDown(r.dispose);
    t.view.physicalSize = const Size(951, 669);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await r.seed(t, fixture);
    const fold = Rect.fromLTWH(450, 0, 32, 669);
    await t.pumpWidget(
      r.build(
        const ImageAdjustScreen(),
        size: const Size(951, 669),
        padding: const EdgeInsets.only(right: 72),
        folds: [fold],
      ),
    );
    await t.pumpAndSettle();
    expect(t.getRect(find.byType(StudioCanvas)).overlaps(fold), isFalse);
    expect(t.getRect(find.text('裁剪').last).overlaps(fold), isFalse);
    await t.pumpWidget(const SizedBox());
  });
}
