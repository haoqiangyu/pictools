import 'package:flutter/services.dart';
import '../models/export_format.dart';
import 'platform_capabilities.dart';

/// Adds a new copy without requesting access to existing library assets.
class PhotoLibraryService {
  static const channel = MethodChannel('pictools/photo_library');
  static bool get available => PlatformCapabilities.isMobile;

  static Future<void> ensurePermission() async {
    if (!available) throw const FormatException('photosUnavailable');
    await channel.invokeMethod<void>('requestPermission');
  }

  static Future<void> save({
    required Uint8List bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    if (!available) throw const FormatException('photosUnavailable');
    if (!format.supportsPhotos) throw const FormatException('photosFormats');
    await channel.invokeMethod<void>('saveImage', {
      'bytes': bytes,
      'fileName': fileName,
      'extension': format.extension,
    });
  }

  static Future<void> openSettings() => channel.invokeMethod('openSettings');

  static String errorKey(Object error) {
    if (error is FormatException) return error.message;
    if (error is PlatformException) {
      if (error.code == 'permission_denied') return 'photosPermissionDenied';
      if (error.code == 'permission_restricted') return 'photosRestricted';
    }
    return 'photosSaveError';
  }
}
