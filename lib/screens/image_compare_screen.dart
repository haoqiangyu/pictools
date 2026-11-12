import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_compare_provider.dart';
import '../models/comparison_mode.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../services/window_arguments.dart';
import '../widgets/studio_widgets.dart';
import '../widgets/studio_canvas.dart';

class ImageCompareScreen extends StatefulWidget {
  const ImageCompareScreen({super.key, this.isStandaloneWindow = false});
  final bool isStandaloneWindow;
  @override
  State<ImageCompareScreen> createState() => _ImageCompareScreenState();
}

class _ImageCompareScreenState extends State<ImageCompareScreen> {
  @override
  void initState() {
    super.initState();
    restoreWindow(
      widget.isStandaloneWindow,
      (s) => context.read<ImageCompareProvider>().importState(s),
    );
  }

  Future<void> _pick(bool a) async {
    final image = await pickStudioImage(context);
    if (image == null || !mounted) return;
    final p = context.read<ImageCompareProvider>();
    if (a) {
      p.setImageA(image.data, name: image.name, path: image.path);
    } else {
      p.setImageB(image.data, name: image.name, path: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImageCompareProvider>();
    final detach = detachAction(
      context,
      widget.isStandaloneWindow,
      WindowType.imageCompare,
      p.exportState,
    );
    final has = p.imageA != null || p.imageB != null;
    return SessionExit(
      hasSession: has && !widget.isStandaloneWindow,
      onDiscard: p.reset,
      child: StudioScaffold(
        title: context.s('compareShort'),
        isStandaloneWindow: widget.isStandaloneWindow,
        actions: [
          if (has)
            StudioAction(
              context.s('clearConfirm'),
              Icons.delete_outline,
              () async {
                final clear = await showStudioDialog<bool>(
                  context,
                  StudioPrompt(
                    title: context.s('clearConfirm'),
                    message: context.s('originalKept'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.s('cancel')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.s('discard')),
                      ),
                    ],
                  ),
                );
                if (clear == true) p.reset();
              },
            ),
          ?detach,
        ],
        body: !has
            ? StudioEmpty(
                title: context.s('compareShort'),
                description: context.s('emptyCompare'),
                icon: Icons.compare,
                onImage: (image) =>
                    p.setImageA(image.data, name: image.name, path: image.path),
              )
            : StudioWorkspace(
                preview: StudioCanvas(
                  data: p.imageA ?? p.imageB!,
                  second: p.hasBothImages ? p.imageB : null,
                  mode: p.mode,
                  position: p.sliderPosition,
                  onPositionChanged: p.setSliderPosition,
                  overlayOpacity: p.overlayOpacity,
                ),
                inspector: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioFileTile(
                      label: 'A',
                      name: p.imageAName ?? context.s('selectImage'),
                      data: p.imageA,
                      onTap: () => _pick(true),
                    ),
                    const SizedBox(height: 8),
                    StudioFileTile(
                      label: 'B',
                      name: p.imageBName ?? context.s('selectImage'),
                      data: p.imageB,
                      onTap: () => _pick(false),
                    ),
                    const SizedBox(height: 20),
                    if (!p.hasBothImages)
                      StudioNotice(context.s('emptyCompare'))
                    else ...[
                      StudioSegments<ComparisonMode>(
                        items: {
                          for (final m in ComparisonMode.values)
                            m: m.displayName,
                        },
                        value: p.mode,
                        onChanged: p.setMode,
                      ),
                      const SizedBox(height: 20),
                      if (p.mode != ComparisonMode.sideBySide) ...[
                        Text(
                          '${context.s(p.mode == ComparisonMode.slider ? 'position' : 'opacity')} · ${((p.mode == ComparisonMode.slider ? p.sliderPosition : p.overlayOpacity) * 100).round()}%',
                        ),
                        Slider(
                          value: p.mode == ComparisonMode.slider
                              ? p.sliderPosition
                              : p.overlayOpacity,
                          divisions: 100,
                          label:
                              '${((p.mode == ComparisonMode.slider ? p.sliderPosition : p.overlayOpacity) * 100).round()}%',
                          onChanged: p.mode == ComparisonMode.slider
                              ? p.setSliderPosition
                              : p.setOverlayOpacity,
                        ),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _position(p, 0),
                              child: const Text('0%'),
                            ),
                            TextButton(
                              onPressed: () => _position(p, .5),
                              child: const Text('50%'),
                            ),
                            TextButton(
                              onPressed: () => _position(p, 1),
                              child: const Text('100%'),
                            ),
                          ],
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () {
                          final a = p.imageA,
                              an = p.imageAName,
                              ap = p.imageAPath;
                          p.setImageA(
                            p.imageB,
                            name: p.imageBName,
                            path: p.imageBPath,
                          );
                          p.setImageB(a, name: an, path: ap);
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(context.s('swapImages')),
                      ),
                    ],
                    const SizedBox(height: 16),
                    StudioNotice(context.s('compareFitNote')),
                  ],
                ),
              ),
      ),
    );
  }

  void _position(ImageCompareProvider p, double value) {
    if (p.mode == ComparisonMode.slider) {
      p.setSliderPosition(value);
    } else {
      p.setOverlayOpacity(value);
    }
  }
}
