import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pictools/l10n/app_localizations.dart';
import 'package:pictools/theme/app_theme.dart';
import 'package:pictools/widgets/export_sheet.dart';
import 'package:pictools/providers/image_enhance_provider.dart';
import 'package:pictools/providers/image_adjust_provider.dart';

class FakePicker extends FilePicker {
  String? result;
  int calls = 0;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    calls++;
    return result;
  }
}

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);
void main() {
  testWidgets(
    'cancelled save retains result and retry saves without re-encoding',
    (t) async {
      final picker = FakePicker();
      FilePicker.platform = picker;
      var encodes = 0;
      await t.pumpWidget(
        host(
          ExportSheet(
            name: 'coast.png',
            size: const Size(400, 200),
            encode: (_) async {
              encodes++;
              return Uint8List.fromList([1, 2, 3]);
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      final save = find.text('Save to Files');
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pumpAndSettle();
      expect(encodes, 1);
      expect(picker.calls, 1);
      expect(find.text('Saved'), findsNothing);
      expect(find.textContaining('cancelled'), findsOneWidget);
      picker.result = '/test/coast.png';
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pumpAndSettle();
      expect(encodes, 1);
      expect(picker.calls, 2);
      expect(find.text('Continue editing'), findsOneWidget);
    },
  );
  testWidgets('invalid names cannot start an export', (t) async {
    var encodes = 0;
    await t.pumpWidget(
      host(
        ExportSheet(
          name: 'coast.png',
          size: const Size(400, 200),
          encode: (_) async {
            encodes++;
            return Uint8List(0);
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '../bad');
    await t.pump();
    final button = t.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save to Files'),
    );
    expect(button.onPressed, isNull);
    expect(encodes, 0);
  });
  testWidgets('replacement and clear invalidate old enhancement work', (
    t,
  ) async {
    final deferred = Completer<Uint8List>();
    final p = ImageEnhanceProvider(enhancer: (_) => deferred.future);
    addTearDown(p.dispose);
    final first = img.encodePng(img.Image(width: 8, height: 4));
    final second = img.encodePng(img.Image(width: 4, height: 8));
    await t.runAsync(() => p.setImage(first, name: 'first'));
    final work = p.enhance();
    await t.runAsync(() => p.setImage(second, name: 'second'));
    deferred.complete(first);
    await work;
    expect(p.fileName, 'second');
    expect(p.hasEnhanced, isFalse);
    expect(p.isProcessing, isFalse);
    expect(p.originalSize, const Size(4, 8));
  });
  testWidgets('failed import leaves current image and dimensions intact', (
    t,
  ) async {
    final p = ImageAdjustProvider();
    addTearDown(p.dispose);
    final bytes = img.encodePng(img.Image(width: 8, height: 4));
    await t.runAsync(() => p.setImage(bytes, name: 'valid'));
    Object? error;
    await t.runAsync(() async {
      try {
        await p.setImage(Uint8List.fromList([1, 2, 3]), name: 'invalid');
      } catch (e) {
        error = e;
      }
    });
    expect(error, isNotNull);
    expect(p.fileName, 'valid');
    expect(p.originalSize, const Size(8, 4));
  });
}
