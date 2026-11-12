import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/studio_localizations.dart';
import '../models/comparison_mode.dart';
import '../theme/app_theme.dart';
import 'crop_overlay.dart';
import '../services/internal_clipboard_service.dart';
import '../services/platform_capabilities.dart';
import 'studio_widgets.dart';

class StudioCanvas extends StatefulWidget {
  const StudioCanvas({
    super.key,
    required this.data,
    this.size,
    this.crop,
    this.aspectRatio,
    this.onCropChanged,
    this.second,
    this.mode = ComparisonMode.slider,
    this.position = .5,
    this.onPositionChanged,
    this.overlayOpacity = .5,
    this.busy = false,
  });
  final Uint8List data;
  final Size? size;
  final Rect? crop;
  final double? aspectRatio;
  final ValueChanged<Rect>? onCropChanged;
  final Uint8List? second;
  final ComparisonMode mode;
  final double position, overlayOpacity;
  final ValueChanged<double>? onPositionChanged;
  final bool busy;
  @override
  State<StudioCanvas> createState() => _StudioCanvasState();
}

class _StudioCanvasState extends State<StudioCanvas> {
  final _transform = TransformationController();
  Size? _viewport;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StudioCanvas old) {
    super.didUpdateWidget(old);
    if (!identical(old.data, widget.data)) {
      _transform.value = Matrix4.identity();
    }
  }

  Widget _image(Uint8List data) => Image.memory(
    data,
    fit: BoxFit.contain,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, e, s) =>
        const Icon(Icons.broken_image_outlined, color: Colors.white),
  );
  @override
  Widget build(BuildContext context) => GestureDetector(
    onSecondaryTapDown: PlatformCapabilities.isDesktop
        ? (details) async {
            final selected = await showMenu<bool>(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                0,
                0,
              ),
              items: [
                PopupMenuItem(value: true, child: Text(context.s('copyInApp'))),
              ],
            );
            if (selected == true) {
              await InternalClipboardService.instance.copyImage(
                widget.second ?? widget.data,
                fileName: 'image.png',
              );
              if (context.mounted) {
                studioMessage(context, context.s('copiedInApp'));
              }
            }
          }
        : null,
    child: ColoredBox(
      color: AppTheme.canvas,
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxHeight < 180;
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 8 : 16),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final size = Size(box.maxWidth, box.maxHeight);
                      if (_viewport != null &&
                          _viewport != size &&
                          !_viewport!.isEmpty &&
                          !size.isEmpty) {
                        final old = _viewport!;
                        final m = _transform.value.clone();
                        m.setTranslationRaw(
                          m.storage[12] * size.width / old.width,
                          m.storage[13] * size.height / old.height,
                          0,
                        );
                        _transform.value = m;
                      }
                      _viewport = size;
                      if (widget.crop != null && widget.size != null) {
                        // Tiny keyboard previews cannot fit 48 dp crop handles.
                        if (c.maxHeight < 120) {
                          return _image(widget.data);
                        }
                        final fitted = applyBoxFit(
                          BoxFit.contain,
                          widget.size!,
                          size,
                        ).destination;
                        return Center(
                          child: SizedBox(
                            width: fitted.width,
                            height: fitted.height,
                            child: Stack(
                              fit: StackFit.expand,
                              clipBehavior: Clip.none,
                              children: [
                                _image(widget.data),
                                CropOverlay(
                                  imageSize: widget.size!,
                                  cropRect: widget.crop!,
                                  aspectRatio: widget.aspectRatio,
                                  onCropRectChanged: widget.onCropChanged,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      Widget content;
                      if (widget.second == null) {
                        content = _image(widget.data);
                      } else if (widget.mode == ComparisonMode.sideBySide) {
                        content = Row(
                          children: [
                            Expanded(child: _image(widget.data)),
                            const SizedBox(width: 12),
                            Expanded(child: _image(widget.second!)),
                          ],
                        );
                      } else {
                        content = Stack(
                          fit: StackFit.expand,
                          children: [
                            _image(widget.data),
                            if (widget.mode == ComparisonMode.overlay)
                              Opacity(
                                opacity: widget.overlayOpacity,
                                child: _image(widget.second!),
                              )
                            else
                              ClipRect(
                                clipper: _SplitClipper(widget.position),
                                child: _image(widget.second!),
                              ),
                          ],
                        );
                      }
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          InteractiveViewer(
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: 5,
                            child: SizedBox(
                              width: size.width,
                              height: size.height,
                              child: content,
                            ),
                          ),
                          if (widget.second != null &&
                              widget.mode == ComparisonMode.slider) ...[
                            Positioned(
                              left: (size.width * widget.position).clamp(
                                1,
                                size.width - 1,
                              ),
                              top: 0,
                              bottom: 0,
                              child: const SizedBox(
                                width: 2,
                                child: ColoredBox(color: Colors.white),
                              ),
                            ),
                            Positioned(
                              left: (size.width * widget.position - 24).clamp(
                                0,
                                (size.width - 48).clamp(0, double.infinity),
                              ),
                              top: (size.height - 48) / 2,
                              child: Semantics(
                                label: context.s('position'),
                                value: '${(widget.position * 100).round()}%',
                                increasedValue:
                                    '${(widget.position * 100 + 5).clamp(0, 100).round()}%',
                                decreasedValue:
                                    '${(widget.position * 100 - 5).clamp(0, 100).round()}%',
                                onIncrease: () => widget.onPositionChanged
                                    ?.call((widget.position + .05).clamp(0, 1)),
                                onDecrease: () => widget.onPositionChanged
                                    ?.call((widget.position - .05).clamp(0, 1)),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragUpdate: (d) =>
                                      widget.onPositionChanged?.call(
                                        (widget.position +
                                                d.delta.dx / size.width)
                                            .clamp(0, 1),
                                      ),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.unfold_more,
                                          size: 24,
                                          color: AppTheme.canvas,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (widget.busy)
                            ColoredBox(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      context.s('processing'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (!compact)
                TextButton.icon(
                  onPressed: () => _transform.value = Matrix4.identity(),
                  icon: const Icon(Icons.fit_screen, size: 18),
                  label: Text(context.s('fitCanvas')),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF5F5EF),
                    textStyle: const TextStyle(fontSize: 12),
                    minimumSize: const Size(48, 48),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.position);
  final double position;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * position, size.height);
  @override
  bool shouldReclip(_SplitClipper old) => old.position != position;
}
