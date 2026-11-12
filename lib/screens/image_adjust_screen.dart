import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/adjust_mode.dart';
import '../models/aspect_ratio.dart';
import '../providers/image_adjust_provider.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../services/image_import_service.dart';
import '../services/image_processing_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/studio_widgets.dart';
import '../widgets/studio_canvas.dart';
import '../widgets/export_sheet.dart';

class ImageAdjustScreen extends StatefulWidget {
  const ImageAdjustScreen({super.key, this.isStandaloneWindow = false});
  final bool isStandaloneWindow;
  @override
  State<ImageAdjustScreen> createState() => _ImageAdjustScreenState();
}

class _ImageAdjustScreenState extends State<ImageAdjustScreen> {
  final _width = TextEditingController(), _height = TextEditingController();
  final _widthFocus = FocusNode(), _heightFocus = FocusNode();
  String? _validation;
  @override
  void initState() {
    super.initState();
    restoreWindow(
      widget.isStandaloneWindow,
      (s) => context.read<ImageAdjustProvider>().importState(s),
    );
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    _widthFocus.dispose();
    _heightFocus.dispose();
    super.dispose();
  }

  Future<void> _load(ImportedImage image) => context
      .read<ImageAdjustProvider>()
      .setImage(image.data, name: image.name, path: image.path);
  void _sync(ImageAdjustProvider p) {
    if (!_widthFocus.hasFocus && _width.text != '${p.targetWidth}') {
      _width.text = '${p.targetWidth}';
    }
    if (!_heightFocus.hasFocus && _height.text != '${p.targetHeight}') {
      _height.text = '${p.targetHeight}';
    }
  }

  void _dimension(String value, bool width, ImageAdjustProvider p) {
    final v = int.tryParse(value);
    if (v == null || v < 1 || v > 16384) {
      setState(() => _validation = 'invalidDimension');
      return;
    }
    if (width) {
      p.setTargetWidth(v);
      if (p.lockAspectRatio) _height.text = '${p.targetHeight}';
    } else {
      p.setTargetHeight(v);
      if (p.lockAspectRatio) _width.text = '${p.targetWidth}';
    }
    setState(
      () => _validation = p.targetWidth > 16384 || p.targetHeight > 16384
          ? 'invalidDimension'
          : p.targetWidth * p.targetHeight > ImageImportService.maxPixels
          ? 'pixelLimit'
          : null,
    );
  }

  Future<void> _export(ImageAdjustProvider p) async {
    FocusScope.of(context).unfocus();
    if (_validation != null && p.mode == AdjustMode.resize) return;
    final data = p.imageData!, r = p.cropRect;
    final resize = p.mode == AdjustMode.resize;
    final w = resize
            ? p.targetWidth
            : (r.width * p.originalSize!.width).round().clamp(1, 16384),
        h = resize
            ? p.targetHeight
            : (r.height * p.originalSize!.height).round().clamp(1, 16384);
    await showExportSheet(
      context,
      name: p.fileName ?? 'image',
      size: Size(w.toDouble(), h.toDouble()),
      encode: (options) => ImageProcessingService.export(
        data,
        options,
        width: resize ? w : null,
        height: resize ? h : null,
        crop: resize ? null : [r.left, r.top, r.width, r.height],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImageAdjustProvider>();
    _sync(p);
    final action = StudioAction(
      context.s('exportImage'),
      Icons.download_outlined,
      p.hasImage && (_validation == null || p.mode == AdjustMode.crop)
          ? () => _export(p)
          : null,
    );
    final detach = detachAction(
      context,
      widget.isStandaloneWindow,
      WindowType.imageAdjust,
      p.exportState,
    );
    return SessionExit(
      hasSession: p.hasImage && !widget.isStandaloneWindow,
      onDiscard: p.reset,
      child: StudioScaffold(
        title: context.s('adjustTitle'),
        isStandaloneWindow: widget.isStandaloneWindow,
        primary: p.hasImage ? action : null,
        actions: [
          if (p.hasImage)
            StudioAction(context.s('resetAdjustments'), Icons.restart_alt, () {
              FocusScope.of(context).unfocus();
              p.resetToOriginal();
              _width.text = '${p.targetWidth}';
              _height.text = '${p.targetHeight}';
              setState(() => _validation = null);
            }),
          StudioAction(
            context.s('replaceImage'),
            Icons.add_photo_alternate_outlined,
            () async {
              final image = await pickStudioImage(context);
              if (image != null) {
                await _load(image);
                if (mounted) setState(() => _validation = null);
              }
            },
          ),
          ?detach,
        ],
        body: !p.hasImage
            ? StudioEmpty(
                title: context.s('adjustTitle'),
                description: context.s('tool.image_adjust.description'),
                icon: Icons.crop,
                onImage: _load,
              )
            : StudioWorkspace(
                primary: action,
                preview: StudioCanvas(
                  data: p.imageData!,
                  size: p.originalSize,
                  crop: p.mode == AdjustMode.crop ? p.cropRect : null,
                  aspectRatio: p.aspectRatio.ratio,
                  onCropChanged: p.setCropRect,
                ),
                inspector: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioSegments<AdjustMode>(
                      items: {
                        AdjustMode.crop: context.s('crop'),
                        AdjustMode.resize: context.s('size'),
                      },
                      value: p.mode,
                      onChanged: p.setMode,
                    ),
                    const SizedBox(height: 12),
                    if (p.mode == AdjustMode.crop) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final ratio in AspectRatioPreset.values)
                            ChoiceChip(
                              label: Text(ratio.displayName),
                              selected: p.aspectRatio == ratio,
                              onSelected: (_) => p.setAspectRatio(ratio),
                              showCheckmark: false,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${context.s('cropResult')}  ${(p.cropRect.width * p.originalSize!.width).round()} × ${(p.cropRect.height * p.originalSize!.height).round()} px',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.studio.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        title: Text(
                          context.s('preciseCrop'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        children: [
                          for (final entry in [
                            (context.s('cropWidth'), p.cropRect.width, true),
                            (context.s('cropHeight'), p.cropRect.height, false),
                          ])
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${entry.$1} ${(entry.$2 * 100).round()}%',
                                ),
                                Slider(
                                  value: entry.$2.clamp(.02, 1),
                                  min: .02,
                                  max: 1,
                                  divisions: 98,
                                  onChanged:
                                      p.aspectRatio != AspectRatioPreset.free
                                      ? null
                                      : (v) {
                                          final r = p.cropRect;
                                          final w = entry.$3 ? v : r.width,
                                              h = entry.$3 ? r.height : v;
                                          p.setCropRect(
                                            Rect.fromLTWH(
                                              r.left.clamp(0, 1 - w),
                                              r.top.clamp(0, 1 - h),
                                              w,
                                              h,
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),
                          Wrap(
                            children: [
                              IconButton(
                                tooltip: context.s('moveLeft'),
                                onPressed: () => _move(p, -.02, 0),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              IconButton(
                                tooltip: context.s('moveUp'),
                                onPressed: () => _move(p, 0, -.02),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: context.s('moveDown'),
                                onPressed: () => _move(p, 0, .02),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                tooltip: context.s('moveRight'),
                                onPressed: () => _move(p, .02, 0),
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      _field(p, true),
                      const SizedBox(height: 16),
                      _field(p, false),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.s('lockAspectRatio')),
                        value: p.lockAspectRatio,
                        onChanged: (lock) {
                          p.setLockAspectRatio(lock);
                          _dimension(_width.text, true, p);
                        },
                      ),
                      if (_validation != null)
                        StudioNotice(context.s(_validation!), error: true),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final dim in [1080, 1920, 2048])
                            ActionChip(
                              label: Text('$dim px'),
                              onPressed: () {
                                _width.text = '$dim';
                                _dimension('$dim', true, p);
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '${context.s('original')}  ${p.originalSize!.width.round()} × ${p.originalSize!.height.round()} px',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.studio.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StudioNotice(context.s('newCopy'), success: true),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _field(ImageAdjustProvider p, bool width) => TextField(
    key: ValueKey(width ? 'output-width' : 'output-height'),
    controller: width ? _width : _height,
    focusNode: width ? _widthFocus : _heightFocus,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(5),
    ],
    textInputAction: width ? TextInputAction.next : TextInputAction.done,
    onSubmitted: (_) {
      if (width) {
        _heightFocus.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    },
    onChanged: (v) => _dimension(v, width, p),
    decoration: InputDecoration(
      labelText: context.s(width ? 'width' : 'height'),
      suffixText: 'px',
    ),
  );
  void _move(ImageAdjustProvider p, double dx, double dy) {
    final r = p.cropRect;
    p.setCropRect(
      Rect.fromLTWH(
        (r.left + dx).clamp(0, 1 - r.width),
        (r.top + dy).clamp(0, 1 - r.height),
        r.width,
        r.height,
      ),
    );
  }
}
