import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// 剪切板图片数据
class ClipboardImage {
  final Uint8List data;
  final String? fileName;
  final String? filePath;
  final DateTime copiedAt;

  ClipboardImage({
    required this.data,
    this.fileName,
    this.filePath,
    required this.copiedAt,
  });
}

/// 应用内剪切板服务（基于文件系统，支持跨窗口）
class InternalClipboardService {
  static final InternalClipboardService instance = InternalClipboardService._();

  InternalClipboardService._();

  static const String _clipboardFileName = 'pictools_clipboard.png';
  static const String _metaFileName = 'pictools_clipboard_meta.txt';

  File get _clipboardFile {
    final tempDir = Directory.systemTemp;
    return File(path.join(tempDir.path, _clipboardFileName));
  }

  File get _metaFile {
    final tempDir = Directory.systemTemp;
    return File(path.join(tempDir.path, _metaFileName));
  }

  Future<bool> hasImage() async {
    return await _clipboardFile.exists();
  }

  Future<ClipboardImage?> currentImage() async {
    try {
      if (!await _clipboardFile.exists()) return null;

      final data = await _clipboardFile.readAsBytes();
      String? fileName;

      if (await _metaFile.exists()) {
        fileName = await _metaFile.readAsString();
      }

      return ClipboardImage(
        data: data,
        fileName: fileName ?? 'clipboard_image.png',
        filePath: null,
        copiedAt: (await _clipboardFile.stat()).modified,
      );
    } catch (e) {
      debugPrint('❌ Failed to read clipboard: $e');
      return null;
    }
  }

  Future<void> copyImage(
    Uint8List data, {
    String? fileName,
    String? filePath,
  }) async {
    try {
      await _clipboardFile.writeAsBytes(data);
      if (fileName != null) {
        await _metaFile.writeAsString(fileName);
      }
      debugPrint('📋 Image copied: ${fileName ?? "unnamed"}');
    } catch (e) {
      debugPrint('❌ Failed to copy: $e');
    }
  }

  Future<ClipboardImage?> pasteImage() async {
    final image = await currentImage();
    if (image != null) {
      debugPrint('📥 Image pasted: ${image.fileName}');
    }
    return image;
  }

  Future<void> clear() async {
    try {
      if (await _clipboardFile.exists()) await _clipboardFile.delete();
      if (await _metaFile.exists()) await _metaFile.delete();
    } catch (e) {
      debugPrint('❌ Failed to clear: $e');
    }
  }
}
