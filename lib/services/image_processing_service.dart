import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/export_format.dart';
import '../src/rust/api/image_codec.dart' as rust_codec;
import '../src/rust/api/image_enhance.dart' as rust_enhance;
import 'platform_capabilities.dart';

class ImageProcessingService {
  ImageProcessingService._();

  static Future<Uint8List> encode(
    Uint8List imageData,
    ExportFormat format, {
    int quality = 90,
  }) async {
    if (PlatformCapabilities.supportsRustProcessing) {
      return rust_codec.encodeImage(
        imageData: imageData,
        format: format.toRustFormat(quality: quality),
      );
    }

    return compute(_encodeInDart, _EncodeRequest(imageData, format, quality));
  }

  static Future<Uint8List> enhance(Uint8List imageData) async {
    if (PlatformCapabilities.supportsRustProcessing) {
      return rust_enhance.enhanceImage(imageData: imageData);
    }
    return compute(_enhanceInDart, imageData);
  }

  static Future<Uint8List> resizeAndEncode(
    Uint8List imageData, {
    required int width,
    required int height,
    required ExportFormat format,
  }) => _transformAndEncode(
    _TransformRequest.resize(imageData, width, height, format),
  );

  static Future<Uint8List> cropAndEncode(
    Uint8List imageData, {
    required double left,
    required double top,
    required double width,
    required double height,
    required ExportFormat format,
  }) => _transformAndEncode(
    _TransformRequest.crop(imageData, left, top, width, height, format),
  );

  static Future<Uint8List> _transformAndEncode(
    _TransformRequest request,
  ) async {
    if (!PlatformCapabilities.supportsRustProcessing) {
      return compute(_transformAndEncodeInDart, request);
    }
    final png = await compute(
      _transformAndEncodeInDart,
      request.withFormat(ExportFormat.png),
    );
    return encode(png, request.format);
  }
}

class _EncodeRequest {
  const _EncodeRequest(this.data, this.format, this.quality);

  final Uint8List data;
  final ExportFormat format;
  final int quality;
}

class _TransformRequest {
  const _TransformRequest.resize(
    this.data,
    this.targetWidth,
    this.targetHeight,
    this.format,
  ) : cropLeft = null,
      cropTop = null,
      cropWidth = null,
      cropHeight = null;

  const _TransformRequest.crop(
    this.data,
    this.cropLeft,
    this.cropTop,
    this.cropWidth,
    this.cropHeight,
    this.format,
  ) : targetWidth = null,
      targetHeight = null;

  final Uint8List data;
  final int? targetWidth;
  final int? targetHeight;
  final double? cropLeft;
  final double? cropTop;
  final double? cropWidth;
  final double? cropHeight;
  final ExportFormat format;

  _TransformRequest withFormat(ExportFormat newFormat) => targetWidth != null
      ? _TransformRequest.resize(data, targetWidth!, targetHeight!, newFormat)
      : _TransformRequest.crop(
          data,
          cropLeft!,
          cropTop!,
          cropWidth!,
          cropHeight!,
          newFormat,
        );
}

Uint8List _encodeInDart(_EncodeRequest request) {
  final image = img.decodeImage(request.data);
  if (image == null) {
    throw const FormatException('无法解码图片，请确认文件格式有效');
  }

  return _encodeImage(image, request.format, request.quality);
}

Uint8List _transformAndEncodeInDart(_TransformRequest request) {
  final source = img.decodeImage(request.data);
  if (source == null) {
    throw const FormatException('无法解码图片，请确认文件格式有效');
  }

  final img.Image result;
  if (request.targetWidth != null) {
    result = img.copyResize(
      source,
      width: request.targetWidth!,
      height: request.targetHeight!,
      interpolation: img.Interpolation.cubic,
    );
  } else {
    result = img.copyCrop(
      source,
      x: (request.cropLeft! * source.width).round(),
      y: (request.cropTop! * source.height).round(),
      width: (request.cropWidth! * source.width).round().clamp(1, source.width),
      height: (request.cropHeight! * source.height).round().clamp(
        1,
        source.height,
      ),
    );
  }
  return _encodeImage(result, request.format, 90);
}

Uint8List _encodeImage(img.Image image, ExportFormat format, int quality) {
  return switch (format) {
    ExportFormat.png => img.encodePng(image),
    ExportFormat.jpg => img.encodeJpg(image, quality: quality),
    ExportFormat.webp => img.encodeWebP(image),
    ExportFormat.bmp => img.encodeBmp(image),
    ExportFormat.ico => img.encodeIco(image),
    ExportFormat.tiff => img.encodeTiff(image),
  };
}

Uint8List _enhanceInDart(Uint8List data) {
  final image = img.decodeImage(data);
  if (image == null) {
    throw const FormatException('无法解码图片，请确认文件格式有效');
  }

  for (final frame in image.frames) {
    for (final pixel in frame) {
      final alpha = pixel.a;
      final red = _enhanceChannel(pixel.r.toDouble());
      final green = _enhanceChannel(pixel.g.toDouble());
      final blue = _enhanceChannel(pixel.b.toDouble());
      pixel
        ..r = red
        ..g = green
        ..b = blue
        ..a = alpha;
    }
  }
  return img.encodePng(image);
}

num _enhanceChannel(double channel) {
  final normalized = channel / 255.0;
  final linear = normalized <= 0.04045
      ? normalized / 12.92
      : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  final exposed = (linear * 1.2968395546510096).clamp(0.0, 1.0);
  final srgb = exposed <= 0.0031308
      ? 12.92 * exposed
      : 1.055 * _fifthRootPower(exposed) - 0.055;
  return (srgb.clamp(0.0, 1.0) * 255).round();
}

// x^(1/2.4), kept local so mobile processing does not need another package.
double _fifthRootPower(double value) =>
    value == 0 ? 0 : math.pow(value, 1 / 2.4).toDouble();
