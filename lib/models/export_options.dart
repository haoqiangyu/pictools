import 'export_format.dart';

/// An immutable snapshot prevents an in-flight export changing with the editor.
class ExportOptions {
  const ExportOptions({
    this.format = ExportFormat.png,
    this.quality = 90,
    this.lossless = false,
    this.jpegBackground = 0xFFFFFF,
    this.resizeIco = false,
  });
  final ExportFormat format;
  final int quality, jpegBackground;
  final bool lossless, resizeIco;
  ExportOptions copyWith({
    ExportFormat? format,
    int? quality,
    bool? lossless,
    int? jpegBackground,
    bool? resizeIco,
  }) => ExportOptions(
    format: format ?? this.format,
    quality: quality ?? this.quality,
    lossless: lossless ?? this.lossless,
    jpegBackground: jpegBackground ?? this.jpegBackground,
    resizeIco: resizeIco ?? this.resizeIco,
  );
}
