import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictools/models/export_format.dart';
import 'package:pictools/models/export_options.dart';
import 'package:pictools/models/save_destination.dart';
import 'package:pictools/providers/batch_converter_provider.dart';
import 'package:pictools/services/image_import_service.dart';
import 'package:pictools/services/photo_library_service.dart';
import 'package:pictools/widgets/export_sheet.dart';
import 'package:pictools/widgets/save_destination_sheet.dart';
import 'package:pictools/widgets/studio_widgets.dart';
import 'export_flow_test.dart' show host, FakePicker;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;
  late FakePicker picker;
  setUp(() {
    calls = [];
    picker = FakePicker()..result = '/test/result.png';
    FilePicker.platform = picker;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoLibraryService.channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoLibraryService.channel,
      null,
    );
  });

  testWidgets(
    'save Photos then Files reuses bytes and disables duplicate destination',
    (t) async {
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
      await t.ensureVisible(find.text('Save to Photos'));
      await t.tap(find.text('Save to Photos'));
      await t.pumpAndSettle();
      expect(calls.map((c) => c.method), ['requestPermission', 'saveImage']);
      expect(calls.last.arguments['fileName'], 'coast_pictools.png');
      expect(calls.last.arguments['extension'], 'png');
      expect(find.text('Saved to Photos'), findsNWidgets(2));
      expect(find.text('Save to Photos'), findsNothing);
      await t.ensureVisible(find.text('Save to Files'));
      await t.tap(find.text('Save to Files'));
      await t.pumpAndSettle();
      expect(encodes, 1);
      expect(picker.calls, 1);
      expect(find.text('Saved to Photos and Files'), findsNWidgets(2));
    },
  );

  testWidgets('permission denial preserves export and Files remains usable', (
    t,
  ) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoLibraryService.channel,
      (call) async {
        calls.add(call);
        throw PlatformException(code: 'permission_denied');
      },
    );
    var encodes = 0;
    await t.pumpWidget(
      host(
        ExportSheet(
          name: 'test',
          size: const Size(10, 10),
          encode: (_) async {
            encodes++;
            return Uint8List(4);
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Save to Photos'));
    await t.tap(find.text('Save to Photos'));
    await t.pumpAndSettle();
    expect(encodes, 0);
    expect(find.text('Open Settings'), findsOneWidget);
    await t.ensureVisible(find.text('Save to Files'));
    await t.tap(find.text('Save to Files'));
    await t.pumpAndSettle();
    expect(encodes, 1);
    expect(find.text('Saved to Files'), findsNWidgets(2));
  });

  testWidgets('unsupported formats disable Photos without silent conversion', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        ExportSheet(
          name: 'test',
          size: const Size(10, 10),
          encode: (_) async => Uint8List(4),
        ),
      ),
    );
    await t.pumpAndSettle();
    for (final label in ['WebP', 'BMP', 'ICO', 'TIFF']) {
      await t.ensureVisible(find.text(label));
      await t.tap(find.text(label));
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save to Photos'),
            )
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Save to Files'),
            )
            .onPressed,
        isNotNull,
      );
    }
    expect(calls, isEmpty);
  });

  testWidgets(
    'native save failure can retry using cached bytes; double tap ignored',
    (t) async {
      var encodes = 0;
      final pending = Completer<void>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoLibraryService.channel,
        (call) async {
          calls.add(call);
          if (call.method == 'saveImage') {
            await pending.future;
            throw PlatformException(code: 'save_failed');
          }
          return null;
        },
      );
      await t.pumpWidget(
        host(
          ExportSheet(
            name: 'test',
            size: const Size(10, 10),
            encode: (_) async {
              encodes++;
              return Uint8List(4);
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Save to Photos'));
      await t.tap(find.text('Save to Photos'));
      await t.pump();
      await t.tap(find.text('Save to Photos'));
      await t.pump();
      expect(calls.where((c) => c.method == 'saveImage').length, 1);
      pending.complete();
      await t.pumpAndSettle();
      expect(find.textContaining('Could not save to Photos'), findsOneWidget);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoLibraryService.channel,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      await t.ensureVisible(find.text('Save to Photos'));
      await t.tap(find.text('Save to Photos'));
      await t.pumpAndSettle();
      expect(encodes, 1);
      expect(find.text('Saved to Photos'), findsNWidgets(2));
    },
  );

  test(
    'batch tracks destinations independently and excludes unsupported photos',
    () async {
      final provider = BatchConverterProvider(
        encoder: (_, _) async => Uint8List(4),
      );
      addTearDown(provider.dispose);
      provider.add(ImportedImage(Uint8List(4), 'a.png', width: 4, height: 4));
      await provider.run();
      final first = provider.items.single;
      provider.markSaved(first, SaveDestination.photos);
      expect(first.canSaveTo(SaveDestination.photos), false);
      expect(first.canSaveTo(SaveDestination.files), true);
      provider.markSaved(first, SaveDestination.files);
      expect(first.statusKey, 'savedToBoth');
      provider.setOptions(const ExportOptions(format: ExportFormat.webp));
      provider.add(ImportedImage(Uint8List(4), 'b.webp', width: 4, height: 4));
      await provider.run();
      expect(provider.items.last.canSaveTo(SaveDestination.photos), false);
      expect(provider.items.last.canSaveTo(SaveDestination.files), true);
    },
  );

  testWidgets(
    'busy batch session cannot leave or discard during a native write',
    (t) async {
      var discarded = false;
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionExit(
                    hasSession: true,
                    busy: true,
                    onDiscard: () => discarded = true,
                    child: const Scaffold(body: Text('Saving batch')),
                  ),
                ),
              ),
              child: const Text('Open batch'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open batch'));
      await t.pumpAndSettle();
      final navigator = t.state<NavigatorState>(find.byType(Navigator).first);
      await navigator.maybePop();
      await t.pumpAndSettle();
      expect(find.text('Saving batch'), findsOneWidget);
      expect(find.byType(StudioPrompt), findsNothing);
      expect(discarded, false);
    },
  );

  testWidgets('destination picker fits small screens with large text', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => chooseSaveDestination(
                context,
                photoCount: 2,
                fileCount: 3,
                totalCount: 3,
              ),
              child: const Text('Choose'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Choose'));
    await t.pumpAndSettle();
    expect(find.text('Save to Photos · 2'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
