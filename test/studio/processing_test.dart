import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pictools/models/export_format.dart';
import 'package:pictools/models/export_options.dart';
import 'package:pictools/services/image_import_service.dart';
import 'package:pictools/services/image_processing_service.dart';
import 'package:pictools/providers/batch_converter_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Uint8List source({int w = 400, int h = 200}) =>
      img.encodePng(img.Image(width: w, height: h, numChannels: 4));
  test('checks file contents rather than trusting its extension', () async {
    await expectLater(
      ImageImportService.inspect(Uint8List.fromList([1, 2, 3]), 'image.png'),
      throwsFormatException,
    );
    final image = await ImageImportService.inspect(source(), 'wrong.jpg');
    expect(image.width, 400);
    expect(image.height, 200);
  });
  test(
    'TIFF is normalized for Flutter preview while source stays untouched',
    () async {
      final original = img.encodeTiff(img.Image(width: 40, height: 20));
      final imported = await ImageImportService.inspect(
        original,
        'source.tiff',
        path: '/original.tiff',
      );
      expect(imported.path, isNull);
      expect(img.decodePng(imported.data), isNotNull);
      expect(img.decodeTiff(original)!.width, 40);
    },
  );
  test(
    'JPEG preflight composites transparent pixels onto the chosen color',
    () async {
      for (final c in [0xFFFFFF, 0]) {
        final result = await ImageProcessingService.prepareExport(
          source(w: 4, h: 4),
          ExportOptions(format: ExportFormat.jpg, jpegBackground: c),
        );
        final pixel = img.decodePng(result)!.getPixel(0, 0);
        expect(pixel.r, c == 0 ? 0 : 255);
        expect(pixel.g, pixel.r);
        expect(pixel.b, pixel.r);
      }
    },
  );
  test('ICO requires explicit resampling and retains aspect ratio', () async {
    await expectLater(
      ImageProcessingService.prepareExport(
        source(),
        const ExportOptions(format: ExportFormat.ico),
      ),
      throwsFormatException,
    );
    final result = await ImageProcessingService.prepareExport(
      source(),
      const ExportOptions(format: ExportFormat.ico, resizeIco: true),
    );
    final decoded = img.decodePng(result)!;
    expect((decoded.width, decoded.height), (256, 128));
  });
  test('crop and resize honor pixels and enforce memory limits', () async {
    final crop = img.decodePng(
      await ImageProcessingService.prepareExport(
        source(),
        const ExportOptions(),
        crop: [.25, .25, .5, .5],
      ),
    )!;
    expect((crop.width, crop.height), (200, 100));
    final resize = img.decodePng(
      await ImageProcessingService.prepareExport(
        source(),
        const ExportOptions(),
        width: 300,
        height: 150,
      ),
    )!;
    expect((resize.width, resize.height), (300, 150));
    await expectLater(
      ImageProcessingService.prepareExport(
        source(),
        const ExportOptions(),
        width: 16000,
        height: 16000,
      ),
      throwsFormatException,
    );
  });
  test(
    'batch cancel finishes in-flight item and keeps remaining work resumable',
    () async {
      final completer = Completer<Uint8List>();
      var calls = 0;
      final p = BatchConverterProvider(
        encoder: (bytes, options) async {
          calls++;
          return calls == 1 ? completer.future : bytes;
        },
      );
      addTearDown(p.dispose);
      final bytes = source(w: 4, h: 4);
      p.add(ImportedImage(bytes, 'a.png'));
      p.add(ImportedImage(bytes, 'b.png'));
      final work = p.run();
      expect(p.items.first.status, BatchStatus.processing);
      p.cancel();
      completer.complete(bytes);
      await work;
      expect(p.items.first.status, BatchStatus.ready);
      expect(p.items.last.status, BatchStatus.pending);
      expect(calls, 1);
      await p.run();
      expect(calls, 2);
      expect(p.complete, 2);
      expect(p.items.first.status, BatchStatus.ready);
    },
  );
  test('batch isolates errors and retries only the failed item', () async {
    var fail = true;
    var calls = 0;
    final p = BatchConverterProvider(
      encoder: (bytes, options) async {
        calls++;
        if (fail && calls == 1) throw Exception('codec');
        return bytes;
      },
    );
    addTearDown(p.dispose);
    final bytes = source(w: 4, h: 4);
    p.add(ImportedImage(bytes, 'a.png'));
    p.add(ImportedImage(bytes, 'b.png'));
    await p.run();
    expect(p.items.first.status, BatchStatus.failed);
    expect(p.items.last.status, BatchStatus.ready);
    final completed = p.items.last.result;
    fail = false;
    await p.run(only: p.items.first);
    expect(calls, 3);
    expect(p.complete, 2);
    expect(identical(completed, p.items.last.result), isTrue);
  });
}
