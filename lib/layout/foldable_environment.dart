import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native coordinates are logical points relative to this Flutter view.
/// No device-name or screen-pixel assumptions are used.
class FoldableGeometry {
  const FoldableGeometry({
    this.divisions = const [],
    this.occlusions = const [],
    this.safeInsets = EdgeInsets.zero,
    this.windowSize = Size.zero,
    this.regularWidth = false,
    this.regionsSupported = false,
  });
  final List<Rect> divisions, occlusions;
  final EdgeInsets safeInsets;
  final Size windowSize;
  final bool regularWidth, regionsSupported;
  factory FoldableGeometry.fromMap(Map<Object?, Object?> map) {
    List<Rect> rects(String key) => (map[key] as List? ?? [])
        .map((r) {
          final a = List<num>.from(r as List);
          return Rect.fromLTWH(
            a[0].toDouble(),
            a[1].toDouble(),
            a[2].toDouble(),
            a[3].toDouble(),
          );
        })
        .where((r) => r.isFinite)
        .toList();
    final s = List<num>.from(map['safeInsets'] as List? ?? [0, 0, 0, 0]);
    final size = List<num>.from(map['size'] as List? ?? [0, 0]);
    return FoldableGeometry(
      divisions: rects('divisions'),
      occlusions: rects('occlusions'),
      safeInsets: EdgeInsets.fromLTRB(
        s[0].toDouble(),
        s[1].toDouble(),
        s[2].toDouble(),
        s[3].toDouble(),
      ),
      windowSize: Size(size[0].toDouble(), size[1].toDouble()),
      regularWidth: map['regularWidth'] == true,
      regionsSupported: map['regionsSupported'] == true,
    );
  }
}

class FoldableEnvironment extends StatefulWidget {
  const FoldableEnvironment({super.key, required this.child, this.geometry});
  final Widget child;

  /// Used by embedder integration tests, never exposed as a product pose picker.
  final FoldableGeometry? geometry;
  @override
  State<FoldableEnvironment> createState() => _FoldableEnvironmentState();
  static FoldableGeometry of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FoldableScope>()?.geometry ??
      const FoldableGeometry();
  static List<Rect> divisionsOf(BuildContext context) {
    final native = of(context);
    final media = MediaQuery.of(context);
    // Ignore a stale native event during rotation until view bounds catch up.
    final current =
        native.windowSize == Size.zero ||
        (native.windowSize.width - media.size.width).abs() < 2 &&
            (native.windowSize.height - media.size.height).abs() < 2;
    return [
      if (current) ...native.divisions,
      for (final f in media.displayFeatures)
        if (f.type == ui.DisplayFeatureType.hinge ||
            f.type == ui.DisplayFeatureType.fold &&
                f.state == ui.DisplayFeatureState.postureHalfOpened)
          f.bounds,
    ];
  }
}

class _FoldableEnvironmentState extends State<FoldableEnvironment> {
  StreamSubscription<dynamic>? _subscription;
  FoldableGeometry _geometry = const FoldableGeometry();
  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && widget.geometry == null) {
      _subscription = const EventChannel('pictools/window_geometry')
          .receiveBroadcastStream()
          .listen(
            (value) {
              if (mounted && value is Map) {
                setState(() => _geometry = FoldableGeometry.fromMap(value));
              }
            },
            onError: (Object error) {
              debugPrint(
                'Window geometry unavailable; using Flutter safe areas.',
              );
            },
          );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geometry = widget.geometry ?? _geometry;
    final media = MediaQuery.of(context);
    final current =
        geometry.windowSize == Size.zero ||
        (geometry.windowSize.width - media.size.width).abs() < 2 &&
            (geometry.windowSize.height - media.size.height).abs() < 2;
    var safe = media.padding;
    if (current) {
      safe = EdgeInsets.fromLTRB(
        math.max(safe.left, geometry.safeInsets.left),
        math.max(safe.top, geometry.safeInsets.top),
        math.max(safe.right, geometry.safeInsets.right),
        media.viewInsets.bottom > 0
            ? safe.bottom
            : math.max(safe.bottom, geometry.safeInsets.bottom),
      );
      for (final r in geometry.occlusions) {
        if (r.left <= safe.left && r.height > r.width) {
          safe = safe.copyWith(left: math.max(safe.left, r.right));
        } else if (r.right >= media.size.width - safe.right &&
            r.height > r.width) {
          safe = safe.copyWith(
            right: math.max(safe.right, media.size.width - r.left),
          );
        } else if (r.top <= safe.top) {
          safe = safe.copyWith(top: math.max(safe.top, r.bottom));
        } else if (r.bottom >= media.size.height - safe.bottom) {
          safe = safe.copyWith(
            bottom: math.max(safe.bottom, media.size.height - r.top),
          );
        }
      }
    }
    return _FoldableScope(
      geometry: geometry,
      child: MediaQuery(
        data: media.copyWith(padding: safe),
        child: widget.child,
      ),
    );
  }
}

class _FoldableScope extends InheritedWidget {
  const _FoldableScope({required this.geometry, required super.child});
  final FoldableGeometry geometry;
  @override
  bool updateShouldNotify(_FoldableScope oldWidget) =>
      geometry != oldWidget.geometry;
}

/// Local origin lets descendants map full-view reserved regions after safe-area
/// padding, side controls and the app header have been laid out.
class StudioLayoutScope extends InheritedWidget {
  const StudioLayoutScope({
    super.key,
    required this.origin,
    required this.sideControls,
    this.keyboardVisible = false,
    required this.divisions,
    required super.child,
  });
  final Offset origin;
  final bool sideControls;
  final bool keyboardVisible;
  final List<Rect> divisions;
  static StudioLayoutScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioLayoutScope>();
  @override
  bool updateShouldNotify(StudioLayoutScope oldWidget) =>
      origin != oldWidget.origin ||
      sideControls != oldWidget.sideControls ||
      keyboardVisible != oldWidget.keyboardVisible ||
      divisions != oldWidget.divisions;
}
