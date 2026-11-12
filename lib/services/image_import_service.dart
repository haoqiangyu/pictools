import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class ImportedImage {
  const ImportedImage(
    this.data,
    this.name, {
    this.path,
    this.width = 0,
    this.height = 0,
    this.animated = false,
  });
  final Uint8List data;
  final String name;
  final String? path;
  final int width, height;
  final bool animated;
}

class ImageImportService {
  static const maxPixels = 48000000;
  static const maxDimension = 16384;
  static const maxFileBytes = 80 * 1024 * 1024;
  static Future<List<PlatformFile>> pick({
    bool multiple = false,
    bool photos = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: photos ? FileType.image : FileType.custom,
      // iOS's compatible representation lets the system provide common image
      // encodings. Android's flag re-encodes photos as low-quality JPEG, so do
      // not enable it there. Document imports retain their selected bytes.
      allowCompression: photos && defaultTargetPlatform == TargetPlatform.iOS,
      allowedExtensions: photos
          ? null
          : ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'ico', 'tif', 'tiff', 'gif'],
      allowMultiple: multiple,
      withData: false,
    );
    return result?.files ?? [];
  }

  static Future<ImportedImage> read(PlatformFile file) async {
    if (file.size > maxFileBytes) throw const FormatException('imageTooLarge');
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw const FormatException('imageImportError');
    return inspect(bytes, file.name, path: file.path);
  }

  static Future<ImportedImage> inspect(
    Uint8List data,
    String name, {
    String? path,
  }) async {
    if (data.length > maxFileBytes) {
      throw const FormatException('imageTooLarge');
    }
    final (int, int, bool, Uint8List?) info;
    try {
      info = await compute(_inspect, data);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('imageImportError');
    }
    return ImportedImage(
      info.$4 ?? data,
      name,
      path: info.$4 == null ? path : null,
      width: info.$1,
      height: info.$2,
      animated: info.$3,
    );
  }

  static Future<ImportedImage> firstFrame(ImportedImage image) async {
    final bytes = await compute(_firstFrame, image.data);
    return ImportedImage(
      bytes,
      image.name,
      width: image.width,
      height: image.height,
    );
  }
}

(int, int, bool, Uint8List?) _inspect(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null) throw const FormatException('imageImportError');
  if (info.width <= 0 ||
      info.height <= 0 ||
      info.width > ImageImportService.maxDimension ||
      info.height > ImageImportService.maxDimension ||
      info.width * info.height > ImageImportService.maxPixels) {
    throw const FormatException('pixelLimit');
  }
  // Decode a single frame; do not allocate all frames of an animation.
  final frame = decoder!.decodeFrame(0);
  if (frame == null) throw const FormatException('imageImportError');
  final upright = img.bakeOrientation(frame);
  final normalized = decoder is img.TiffDecoder || decoder is img.IcoDecoder
      ? img.encodePng(upright)
      : null;
  return (upright.width, upright.height, info.numFrames > 1, normalized);
}

Uint8List _firstFrame(Uint8List bytes) {
  final frame = img.decodeImage(bytes, frame: 0);
  if (frame == null) throw const FormatException('imageImportError');
  return img.encodePng(img.bakeOrientation(frame));
}
