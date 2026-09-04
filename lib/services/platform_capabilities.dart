import 'dart:io';

/// Centralizes features that are only available in the desktop build.
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isDesktop => !isMobile;

  static bool get supportsMultiWindow => isDesktop;
  static bool get supportsRustProcessing =>
      isDesktop || Platform.isAndroid || Platform.isIOS;
  static bool get supportsBackgroundRemoval => isDesktop;
}
