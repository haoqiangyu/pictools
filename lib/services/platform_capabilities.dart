import 'package:flutter/foundation.dart';

/// Capabilities follow Flutter's target platform, including embedder tests.
class PlatformCapabilities {
  PlatformCapabilities._();
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
  static bool get supportsMultiWindow => isDesktop;
  static bool get supportsRustProcessing => isDesktop || isMobile;
  static bool get supportsBackgroundRemoval => isDesktop;
}
