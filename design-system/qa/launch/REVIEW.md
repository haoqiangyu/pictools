# Native launch verification — 2026-11-11

Delivered iOS storyboard/assets and Android legacy/API 31+ resources without a new runtime dependency. All platforms show the existing Pictools mark at 96pt/dp against the Studio background. The native window remains while existing Dart initialization runs, and the first Flutter frame takes over. No second splash route or artificial production delay was added.

## Evidence

- iOS simulator debug build passed. Installed the normal application and recorded actual cold starts in both appearances. `ios-launch.mp4` and `ios-launch-dark.mp4` include launch-to-home handoff. `ios-native-*.png` are frames extracted from those recordings (video color conversion is not a color-calibration test).
- LaunchScreen and Main storyboard both resolve `LaunchBackground`; light/dark traits use the same color asset. The logo has fixed 96pt width/height and center constraints for every supported orientation.
- Android AAPT2 compile and link passed using Android 36 SDK, all project resources, min SDK 24, target SDK 36, and a preprocessed manifest.
- Android 15/API 35 emulator independently exercised these exact compiled resources. `android12-system-*.png` capture the real OS starting window; a separate QA Activity holds its first draw for two seconds solely to permit capture. The production app does not contain this test delay or Activity.
- `android-legacy-resource-*.png` render the legacy layer-list in the same native harness after the OS transition completes. This confirms the drawable, colors, dimensions and glyph; it is **not** an Android 11 device test.
- `android12-system-wide.png` verifies the 96dp mark in a 1366×768, 160dpi native window. Emulator size, density and light appearance were restored afterward.
- Automated capture measurements in `native-visual-checks.json` check the mark's centered bounds and the presence of the white glyph. Manual review confirmed the mark is not clipped, system bars remain readable, and there are no text or controls to overflow.
- `flutter analyze`: no issues. Dart behavior was unchanged, so the earlier 71-test suite was not rerun for this resource-only change.
- `git diff --check`: clean.

The generic browser visual smoke checker flags the deliberately plain dark/light background and native PNG physical resolutions. These are documented false positives for an OS launch screen, not missing UI: native splash backgrounds intentionally use one opaque color and contain no CTA. Native image checks and the reviewed recordings are the applicable evidence; the generic checker is **not** reported as passing.

## Remaining validation boundary

A full Android APK build remains blocked by TLS handshake failures while Gradle downloads existing dependencies (see android-build.log). Tried the cached Gradle 8.14 distribution with JDK 21 after the configured 8.14.3 wrapper was unavailable; no Gradle/JDK project settings were changed. The independent native harness verifies the resource behavior but does not replace a complete Flutter Android cold-start test. Android ≤11 hardware/emulator was not available. Native Duo-specific OS placement is not claimed; the startup image follows the system window, while the Flutter home retains existing fold-aware behavior.

## Figma

[Native launch board](https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=41-28434), page Mobile2.0. Ten editable examples cover iOS and Android generations, light/dark, small/landscape and Duo windows. Reused the existing brand component and semantic/dark variables. Added an editable system-mask diagram and launch-to-home prototype routes, including dark phone and wide home targets. Ledger saved locally.

Version history visibly contains **Pictools 2.2 · 原生开屏与首帧交接**. Figma's MCP quota remained exhausted, so the existing local development-plugin workflow was used through the desktop app. The `design-system/launch/figma.js` and `finish.js` files record that migration; do not rerun the initial script on the completed board.
