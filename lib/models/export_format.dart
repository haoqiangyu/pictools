import 'package:pictools/src/rust/api/image_codec.dart';

/// 统一的图片导出格式枚举
enum ExportFormat {
  png,
  jpg,
  webp,
  bmp,
  ico,
  tiff;

  String get displayName {
    switch (this) {
      case ExportFormat.png:
        return 'PNG';
      case ExportFormat.jpg:
        return 'JPG';
      case ExportFormat.webp:
        return 'WebP';
      case ExportFormat.bmp:
        return 'BMP';
      case ExportFormat.ico:
        return 'ICO';
      case ExportFormat.tiff:
        return 'TIFF';
    }
  }

  String get extension {
    switch (this) {
      case ExportFormat.png:
        return 'png';
      case ExportFormat.jpg:
        return 'jpg';
      case ExportFormat.webp:
        return 'webp';
      case ExportFormat.bmp:
        return 'bmp';
      case ExportFormat.ico:
        return 'ico';
      case ExportFormat.tiff:
        return 'tiff';
    }
  }

  /// 转换为 Rust 对应的 ImageFormat
  ImageFormat toRustFormat({int quality = 90}) {
    switch (this) {
      case ExportFormat.png:
        return const ImageFormat.png();
      case ExportFormat.jpg:
        return ImageFormat.jpg(quality: quality);
      case ExportFormat.webp:
        return ImageFormat.webP(quality: quality, lossless: false);
      case ExportFormat.bmp:
        return const ImageFormat.bmp();
      case ExportFormat.ico:
        return const ImageFormat.ico();
      case ExportFormat.tiff:
        return const ImageFormat.tiff();
    }
  }
}
