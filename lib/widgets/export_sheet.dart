import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../models/export_format.dart';
import '../models/export_options.dart';
import '../models/save_destination.dart';
import '../services/photo_library_service.dart';
import '../services/file_export_service.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../theme/app_theme.dart';
import 'studio_widgets.dart';

Future<void> showExportSheet(
  BuildContext context, {
  required String name,
  required Size size,
  required Future<Uint8List> Function(ExportOptions) encode,
}) => showStudioDialog<void>(
  context,
  ExportSheet(name: name, size: size, encode: encode),
);

class ExportSettings extends StatelessWidget {
  const ExportSettings({
    super.key,
    required this.options,
    required this.onChanged,
    this.needsIcoResize = true,
  });
  final ExportOptions options;
  final ValueChanged<ExportOptions>? onChanged;
  final bool needsIcoResize;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSection(
        context.s('exportFormat'),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in ExportFormat.values)
              ChoiceChip(
                label: Text(f.displayName),
                selected: options.format == f,
                onSelected: onChanged == null
                    ? null
                    : (_) => onChanged!(options.copyWith(format: f)),
                showCheckmark: false,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                side: BorderSide(
                  color: options.format == f
                      ? context.studio.primary
                      : context.studio.border,
                ),
              ),
          ],
        ),
      ),
      if (options.format == ExportFormat.jpg ||
          options.format == ExportFormat.webp) ...[
        const SizedBox(height: 16),
        if (options.format == ExportFormat.webp)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.s('lossless')),
            value: options.lossless,
            onChanged: onChanged == null
                ? null
                : (v) => onChanged!(options.copyWith(lossless: v)),
          ),
        if (options.format != ExportFormat.webp || !options.lossless) ...[
          Text(
            '${context.s('quality')} · ${options.quality}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: options.quality.toDouble(),
            min: 10,
            max: 100,
            divisions: 90,
            label: '${options.quality}%',
            onChanged: onChanged == null
                ? null
                : (v) => onChanged!(options.copyWith(quality: v.round())),
            semanticFormatterCallback: (v) => '${v.round()}%',
          ),
        ],
      ],
      if (options.format == ExportFormat.jpg) ...[
        const SizedBox(height: 8),
        StudioSection(
          context.s('jpegBackground'),
          child: StudioSegments<int>(
            items: {0xFFFFFF: context.s('white'), 0: context.s('black')},
            value: options.jpegBackground,
            onChanged: (v) =>
                onChanged?.call(options.copyWith(jpegBackground: v)),
          ),
        ),
        const SizedBox(height: 12),
        StudioNotice(context.s('transparencyNote')),
      ],
      if (options.format == ExportFormat.ico && needsIcoResize) ...[
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.s('icoResize')),
          subtitle: Text(context.s('icoWarning')),
          value: options.resizeIco,
          onChanged: onChanged == null
              ? null
              : (v) => onChanged!(options.copyWith(resizeIco: v ?? false)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    ],
  );
}

class ExportSheet extends StatefulWidget {
  const ExportSheet({
    super.key,
    required this.name,
    required this.size,
    required this.encode,
  });
  final String name;
  final Size size;
  final Future<Uint8List> Function(ExportOptions) encode;
  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  late final TextEditingController _name;
  ExportOptions _options = const ExportOptions();
  Uint8List? _bytes;
  bool _busy = false;
  final Set<SaveDestination> _savedTo = {};
  bool get _saved => _savedTo.isNotEmpty;
  String get _savedKey =>
      _savedTo.length == 2 ? 'savedToBoth' : _savedTo.single.successKey;
  String? _message, _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: '${path.basenameWithoutExtension(widget.name)}_pictools',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _fileName => '${_name.text.trim()}.${_options.format.extension}';
  Size get _outputSize {
    if (_options.format != ExportFormat.ico ||
        !_options.resizeIco ||
        (widget.size.width <= 256 && widget.size.height <= 256)) {
      return widget.size;
    }
    final scale = 256 / math.max(widget.size.width, widget.size.height);
    return Size(
      math.max(1, (widget.size.width * scale).round()).toDouble(),
      math.max(1, (widget.size.height * scale).round()).toDouble(),
    );
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      !RegExp(r'[\\/:*?"<>|\x00-\x1F]').hasMatch(_name.text) &&
      _name.text.length <= 120;
  bool get _icoBlocked =>
      _options.format == ExportFormat.ico &&
      (widget.size.width > 256 || widget.size.height > 256) &&
      !_options.resizeIco;
  Future<void> _save(SaveDestination destination) async {
    if (!_valid || _icoBlocked || _busy || _savedTo.contains(destination)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      if (destination == SaveDestination.photos) {
        await PhotoLibraryService.ensurePermission();
        if (!mounted) return;
      }
      final bytes = _bytes ?? await widget.encode(_options);
      _bytes = bytes;
      if (!mounted) return;
      if (destination == SaveDestination.photos) {
        await PhotoLibraryService.save(
          bytes: bytes,
          fileName: _fileName,
          format: _options.format,
        );
        if (mounted) setState(() => _savedTo.add(destination));
      } else {
        final saved = await FileExportService.save(
          bytes: bytes,
          fileName: _fileName,
          extension: _options.format.extension,
          dialogTitle: context.s('saveToFiles'),
        );
        if (!mounted) return;
        setState(() {
          if (saved != null) _savedTo.add(destination);
          _message = saved == null ? 'saveCancelled' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = destination == SaveDestination.photos
              ? PhotoLibraryService.errorKey(e)
              : e is FormatException
              ? e.message
              : 'exportError',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(BuildContext anchor) async {
    if (_bytes == null || _busy) return;
    final box = anchor.findRenderObject() as RenderBox?;
    final rect = box == null
        ? const Rect.fromLTWH(1, 1, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              _bytes!,
              mimeType: _options.format == ExportFormat.jpg
                  ? 'image/jpeg'
                  : 'image/${_options.format.extension}',
            ),
          ],
          fileNameOverrides: [_fileName],
          sharePositionOrigin: rect,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'shareError');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _saveActions(BuildContext context) => [
    if (PhotoLibraryService.available &&
        !_savedTo.contains(SaveDestination.photos)) ...[
      FilledButton.icon(
        onPressed:
            _busy || !_valid || _icoBlocked || !_options.format.supportsPhotos
            ? null
            : () => _save(SaveDestination.photos),
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(context.s('saveToPhotos')),
      ),
      const SizedBox(height: 8),
      if (!_options.format.supportsPhotos) ...[
        StudioNotice(context.s('photosFormats')),
        const SizedBox(height: 8),
      ],
    ],
    if (!_savedTo.contains(SaveDestination.files))
      OutlinedButton.icon(
        onPressed: _busy || !_valid || _icoBlocked
            ? null
            : () => _save(SaveDestination.files),
        icon: const Icon(Icons.folder_outlined),
        label: Text(context.s('saveToFiles')),
      ),
    if (_busy) ...[
      const SizedBox(height: 12),
      LinearProgressIndicator(semanticsLabel: context.s('saving')),
    ],
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.s(_saved ? _savedKey : 'exportTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.s('close'),
                onPressed: _busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_saved) ...[
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: context.studio.success,
            ),
            const SizedBox(height: 16),
            Text(
              _fileName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(context.s(_savedKey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ..._saveActions(context),
            const SizedBox(height: 24),
            if (!Platform.isLinux)
              Builder(
                builder: (anchor) => OutlinedButton.icon(
                  onPressed: _busy ? null : () => _share(anchor),
                  icon: const Icon(Icons.ios_share),
                  label: Text(context.s('share')),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(context.s('continueEditing')),
            ),
          ] else ...[
            Text(
              '${_outputSize.width.round()} × ${_outputSize.height.round()} px',
              style: TextStyle(color: context.studio.muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              enabled: !_busy,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.s('fileName'),
                suffixText: '.${_options.format.extension}',
                errorText: _valid ? null : context.s('fileNameInvalid'),
              ),
            ),
            const SizedBox(height: 20),
            ExportSettings(
              options: _options,
              needsIcoResize:
                  widget.size.width > 256 || widget.size.height > 256,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _options = v;
                      _bytes = null;
                      _message = null;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 20),
            StudioNotice(context.s('newCopy'), success: true),
            const SizedBox(height: 20),
            ..._saveActions(context),
            if (_bytes != null && !Platform.isLinux)
              Builder(
                builder: (anchor) => TextButton.icon(
                  onPressed: _busy ? null : () => _share(anchor),
                  icon: const Icon(Icons.ios_share),
                  label: Text(context.s('share')),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              context.s('notSaved'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.studio.muted),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            StudioNotice(context.s(_message!)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            StudioNotice(context.s(_error!), error: true),
            if (_error == 'photosPermissionDenied')
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        try {
                          await PhotoLibraryService.openSettings();
                        } catch (_) {
                          if (mounted) {
                            setState(() => _error = 'photosSaveError');
                          }
                        }
                      },
                child: Text(context.s('openSettings')),
              ),
          ],
        ],
      ),
    ),
  );
}
