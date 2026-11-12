import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictools/screens/home_screen.dart';
import 'package:pictools/screens/image_adjust_screen.dart';
import 'package:pictools/screens/image_compare_screen.dart';
import 'package:pictools/screens/image_converter_screen.dart';
import 'package:pictools/screens/image_enhance_screen.dart';
import 'package:pictools/widgets/studio_widgets.dart';
import 'studio_layout_test.dart' show Rig;

class ImportPicker extends FilePicker {
  int calls = 0;
  FileType? lastType;
  bool? multiple, compression;
  List<String>? extensions;
  FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    lastType = type;
    multiple = allowMultiple;
    compression = allowCompression;
    extensions = allowedExtensions;
    return result;
  }
}

void main() {
  late ImportPicker picker;
  late Rig rig;
  setUp(() {
    picker = ImportPicker();
    FilePicker.platform = picker;
    rig = Rig();
  });
  tearDown(() => rig.dispose());

  for (final photos in [true, false]) {
    for (final multiple in [false, true]) {
      testWidgets(
        '${photos ? 'Photos' : 'Files'} routes correctly; multiple=$multiple',
        (t) async {
          List<PlatformFile>? result;
          final file = PlatformFile(name: 'example.png', size: 8);
          picker.result = FilePickerResult([file]);
          await t.pumpWidget(
            rig.build(
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async => result = await pickStudioFiles(
                      context,
                      multiple: multiple,
                    ),
                    child: const Text('Import'),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('Import'));
          await t.pumpAndSettle();
          expect(picker.calls, 0);
          await t.tap(
            find.byKey(
              ValueKey(photos ? 'import-from-photos' : 'import-from-files'),
            ),
          );
          await t.pumpAndSettle();
          expect(picker.calls, 1);
          expect(picker.lastType, photos ? FileType.image : FileType.custom);
          expect(picker.multiple, multiple);
          expect(
            picker.compression,
            photos && defaultTargetPlatform == TargetPlatform.iOS,
          );
          expect(
            picker.extensions,
            photos
                ? isNull
                : containsAll(['png', 'jpeg', 'webp', 'ico', 'tiff']),
          );
          expect(result, [file]);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );
    }
  }

  testWidgets('cancelling source or system picker keeps caller empty', (
    t,
  ) async {
    List<PlatformFile>? result;
    await t.pumpWidget(
      rig.build(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await pickStudioFiles(context),
              child: const Text('Import'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Import'));
    await t.pumpAndSettle();
    await t.tap(find.text('取消'));
    await t.pumpAndSettle();
    expect(result, isEmpty);
    expect(picker.calls, 0);
    await t.tap(find.text('Import'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('import-from-files')));
    await t.pumpAndSettle();
    expect(result, isEmpty);
    expect(picker.calls, 1);
  });

  for (final screen in <String, Widget>{
    'home': const HomeScreen(),
    'compare': const ImageCompareScreen(),
    'adjust': const ImageAdjustScreen(),
    'enhance': const ImageEnhanceScreen(),
    'batch': const ImageConverterScreen(),
  }.entries) {
    testWidgets('${screen.key} primary import offers both sources', (t) async {
      await t.pumpWidget(rig.build(screen.value));
      await t.pumpAndSettle();
      final choose = find.widgetWithText(FilledButton, '选择图片');
      await t.ensureVisible(choose);
      await t.tap(choose);
      // The caller keeps its loading indicator active while the picker is open.
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(find.text('从相册导入'), findsOneWidget);
      expect(find.text('从文件导入'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('import-from-photos')));
      await t.pumpAndSettle();
      expect(picker.lastType, FileType.image);
      expect(picker.multiple, screen.key == 'batch');
      expect(t.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 568), const Size(951, 669)]) {
    testWidgets('source dialog fits $size with large text and fold exclusion', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final folds = size.width > 600
          ? [const Rect.fromLTWH(450, 0, 32, 669)]
          : <Rect>[];
      await t.pumpWidget(
        rig.build(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => pickStudioFiles(context),
                child: const Text('Import'),
              ),
            ),
          ),
          size: size,
          folds: folds,
          scale: 2,
          locale: const Locale('de'),
        ),
      );
      await t.tap(find.text('Import'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('import-from-files')));
      expect(t.takeException(), isNull);
      final dialog = t.getRect(find.byType(ImageSourceSheet));
      for (final fold in folds) {
        expect(dialog.overlaps(fold), isFalse);
      }
    });
  }
}
