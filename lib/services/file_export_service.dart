import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'platform_capabilities.dart';

class FileExportService {
  FileExportService._();

  static Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    String dialogTitle = '保存图片',
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: [extension],
      type: FileType.custom,
      bytes: PlatformCapabilities.isMobile ? bytes : null,
    );
    if (path == null) return null;

    if (PlatformCapabilities.isMobile) {
      return path;
    }

    final outputPath = path.endsWith('.$extension') ? path : '$path.$extension';
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }
}
