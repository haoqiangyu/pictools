import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_enhance_provider.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../services/image_import_service.dart';
import '../services/image_processing_service.dart';
import '../services/window_arguments.dart';
import '../widgets/studio_widgets.dart';
import '../widgets/studio_canvas.dart';
import '../widgets/export_sheet.dart';

class ImageEnhanceScreen extends StatefulWidget {
  const ImageEnhanceScreen({super.key, this.isStandaloneWindow = false});
  final bool isStandaloneWindow;
  @override
  State<ImageEnhanceScreen> createState() => _ImageEnhanceScreenState();
}

class _ImageEnhanceScreenState extends State<ImageEnhanceScreen> {
  double _position = .5;
  @override
  void initState() {
    super.initState();
    restoreWindow(
      widget.isStandaloneWindow,
      (s) => context.read<ImageEnhanceProvider>().importState(s),
    );
  }

  Future<void> _load(ImportedImage i) => context
      .read<ImageEnhanceProvider>()
      .setImage(i.data, name: i.name, path: i.path);
  Future<void> _export(ImageEnhanceProvider p) async {
    final data = p.enhancedData!;
    await showExportSheet(
      context,
      name: p.fileName ?? 'image',
      size: p.originalSize!,
      encode: (options) => ImageProcessingService.export(data, options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImageEnhanceProvider>();
    final detach = detachAction(
      context,
      widget.isStandaloneWindow,
      WindowType.imageEnhance,
      p.exportState,
    );
    final primary = StudioAction(
      context.s(
        p.isProcessing
            ? 'processing'
            : p.hasEnhanced
            ? 'exportImage'
            : p.errorMessage != null
            ? 'retry'
            : 'enhanceShort',
      ),
      p.hasEnhanced ? Icons.download_outlined : Icons.wb_sunny_outlined,
      p.isProcessing
          ? null
          : p.hasEnhanced
          ? () => _export(p)
          : p.enhance,
    );
    return SessionExit(
      hasSession: p.hasImage && !widget.isStandaloneWindow,
      onDiscard: p.reset,
      child: StudioScaffold(
        title: context.s('enhanceShort'),
        isStandaloneWindow: widget.isStandaloneWindow,
        primary: p.hasImage ? primary : null,
        actions: [
          StudioAction(
            context.s('replaceImage'),
            Icons.add_photo_alternate_outlined,
            () async {
              final image = await pickStudioImage(context);
              if (image != null) await _load(image);
            },
          ),
          ?detach,
        ],
        body: !p.hasImage
            ? StudioEmpty(
                title: context.s('enhanceShort'),
                description: context.s('enhanceDescription'),
                icon: Icons.wb_sunny_outlined,
                onImage: _load,
              )
            : StudioWorkspace(
                primary: primary,
                preview: StudioCanvas(
                  data: p.originalData!,
                  second: p.enhancedData,
                  position: _position,
                  onPositionChanged: (v) => setState(() => _position = v),
                  busy: p.isProcessing,
                ),
                inspector: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.s(p.hasEnhanced ? 'enhanced' : 'enhanceShort'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(context.s('enhanceDescription')),
                    const SizedBox(height: 20),
                    if (p.errorMessage != null)
                      StudioNotice(context.s(p.errorMessage!), error: true)
                    else if (p.isProcessing) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(context.s('processing')),
                    ] else if (p.hasEnhanced) ...[
                      StudioSegments<int>(
                        items: {
                          0: context.s('original'),
                          1: context.s('enhanced'),
                        },
                        value: _position >= .5 ? 1 : 0,
                        onChanged: (v) =>
                            setState(() => _position = v.toDouble()),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _position,
                        divisions: 100,
                        onChanged: (v) => setState(() => _position = v),
                        semanticFormatterCallback: (v) =>
                            '${context.s('position')} ${(v * 100).round()}%',
                      ),
                      Text(context.s('resultReady')),
                    ],
                    const SizedBox(height: 20),
                    StudioFileTile(
                      name: p.fileName ?? 'image',
                      data: p.originalData,
                      subtitle:
                          '${p.originalSize!.width.round()} × ${p.originalSize!.height.round()} px',
                    ),
                    const SizedBox(height: 16),
                    StudioNotice(context.s('newCopy'), success: true),
                  ],
                ),
              ),
      ),
    );
  }
}
