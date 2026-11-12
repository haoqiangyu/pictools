import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/batch_converter_provider.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../services/file_export_service.dart';
import '../services/photo_library_service.dart';
import '../models/save_destination.dart';
import '../widgets/save_destination_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/studio_widgets.dart';
import '../widgets/export_sheet.dart';

class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});
  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  bool _importing = false, _saving = false, _stopSaving = false;
  Future<void> _add() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final files = await pickStudioFiles(context, multiple: true);
      for (final f in files) {
        if (!mounted) break;
        final image = await acceptImage(context, f);
        if (image != null && mounted) {
          context.read<BatchConverterProvider>().add(image);
        }
      }
    } catch (e) {
      if (mounted) studioMessage(context, studioError(context, e));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _save(BatchConverterProvider p, {BatchItem? only}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _stopSaving = false;
    });
    SaveDestination? destination;
    try {
      final items = only == null ? List<BatchItem>.of(p.items) : [only];
      destination = await chooseSaveDestination(
        context,
        photoCount: items
            .where((i) => i.canSaveTo(SaveDestination.photos))
            .length,
        fileCount: items
            .where((i) => i.canSaveTo(SaveDestination.files))
            .length,
        totalCount: items.where((i) => i.result != null).length,
      );
      if (!mounted || destination == null) return;
      if (destination == SaveDestination.photos) {
        await PhotoLibraryService.ensurePermission();
      }
      var saved = 0;
      for (final item in items) {
        if (!mounted || _stopSaving) break;
        if (!item.canSaveTo(destination)) continue;
        if (destination == SaveDestination.photos) {
          await PhotoLibraryService.save(
            bytes: item.result!,
            fileName: item.outputName,
            format: item.options!.format,
          );
        } else {
          final result = await FileExportService.save(
            bytes: item.result!,
            fileName: item.outputName,
            extension: item.options!.format.extension,
            dialogTitle: context.s('saveToFiles'),
          );
          if (result == null) {
            if (mounted) {
              studioMessage(context, '${context.s('saveCancelled')} ($saved)');
            }
            return;
          }
        }
        p.markSaved(item, destination);
        saved++;
      }
      if (mounted && saved > 0) {
        studioMessage(context, '${context.s(destination.successKey)} · $saved');
      }
    } catch (e) {
      if (!mounted) return;
      final key = destination == SaveDestination.photos
          ? PhotoLibraryService.errorKey(e)
          : 'exportError';
      await showStudioDialog<void>(
        context,
        StudioPrompt(
          title: context.s('chooseDestination'),
          message: context.s(key),
          actions: [
            if (key == 'photosPermissionDenied')
              TextButton(
                onPressed: () async {
                  try {
                    await PhotoLibraryService.openSettings();
                  } catch (_) {
                    /* Keep results available. */
                  }
                },
                child: Text(context.s('openSettings')),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.s('close')),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BatchConverterProvider>();
    final ready = p.items.any(
      (i) =>
          i.canSaveTo(SaveDestination.files) ||
          (PhotoLibraryService.available &&
              i.canSaveTo(SaveDestination.photos)),
    );
    final action = StudioAction(
      context.s(
        _saving
            ? 'saving'
            : p.running
            ? 'processing'
            : p.canRun
            ? 'startConvert'
            : ready
            ? 'saveResults'
            : 'addImages',
      ),
      p.canRun ? Icons.transform : Icons.download_outlined,
      _saving || p.running || _importing
          ? null
          : p.canRun
          ? () => p.run()
          : ready
          ? () => _save(p)
          : _add,
    );
    final queue = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${context.s('queue')} · ${p.items.length}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${p.complete} / ${p.items.length} ${context.s('ready')}',
          style: TextStyle(color: context.studio.muted),
        ),
        const SizedBox(height: 16),
        if (p.running) ...[
          LinearProgressIndicator(
            value: p.items.isEmpty ? 0 : p.complete / p.items.length,
          ),
          const SizedBox(height: 16),
        ],
        for (final item in p.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioFileTile(
                  name: item.source.name,
                  data: item.source.data,
                  subtitle:
                      '${context.s(item.statusKey)}${item.options == null ? '' : ' · ${item.options!.format.displayName}'}',
                  trailing: item.status == BatchStatus.processing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<String>(
                          enabled: !p.running && !_saving,
                          tooltip: context.s('more'),
                          icon: Icon(
                            item.status == BatchStatus.saved
                                ? Icons.check_circle_outline
                                : Icons.more_horiz,
                            color: item.status == BatchStatus.saved
                                ? context.studio.success
                                : context.studio.ink,
                          ),
                          onSelected: (value) {
                            if (value == 'save') {
                              _save(p, only: item);
                            } else if (value == 'retry') {
                              p.run(only: item);
                            } else {
                              p.remove(item);
                            }
                          },
                          itemBuilder: (_) => [
                            if (item.canSaveTo(SaveDestination.files) ||
                                (PhotoLibraryService.available &&
                                    item.canSaveTo(SaveDestination.photos)))
                              PopupMenuItem(
                                value: 'save',
                                child: Text(context.s('chooseDestination')),
                              ),
                            if (item.status == BatchStatus.failed)
                              PopupMenuItem(
                                value: 'retry',
                                child: Text(context.s('retry')),
                              ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(context.s('remove')),
                            ),
                          ],
                        ),
                ),
                if (item.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: StudioNotice(context.s(item.error!), error: true),
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _importing || p.running || _saving ? null : _add,
          icon: _importing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(context.s('addImages')),
        ),
        if (p.running || _saving)
          TextButton(
            onPressed: p.cancelling
                ? null
                : () {
                    p.cancel();
                    setState(() => _stopSaving = true);
                  },
            child: Text(context.s(p.cancelling ? 'cancelling' : 'cancelQueue')),
          ),
      ],
    );
    return SessionExit(
      busy: _saving,
      hasSession: p.items.isNotEmpty && !p.running && !_saving,
      onDiscard: p.clear,
      child: StudioScaffold(
        title: context.s('convertShort'),
        primary: p.items.isEmpty ? null : action,
        actions: [
          StudioAction(
            context.s('addImages'),
            Icons.add_photo_alternate_outlined,
            _importing || p.running || _saving ? null : _add,
          ),
          if (p.items.isNotEmpty)
            StudioAction(
              context.s('clearConfirm'),
              Icons.delete_outline,
              p.running || _saving
                  ? null
                  : () async {
                      final ok = await showStudioDialog<bool>(
                        context,
                        StudioPrompt(
                          title: context.s('clearConfirm'),
                          message: context.s('unsavedResults'),
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
                      if (ok == true) p.clear();
                    },
            ),
        ],
        body: p.items.isEmpty
            ? StudioEmpty(
                title: context.s('convertShort'),
                description: context.s('batchHint'),
                icon: Icons.transform,
                onImage: p.add,
                onPick: _add,
              )
            : StudioWorkspace(
                previewFraction: .48,
                primary: action,
                preview: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: queue,
                ),
                inspector: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExportSettings(
                      options: p.options,
                      onChanged: p.running || _saving ? null : p.setOptions,
                    ),
                    const SizedBox(height: 16),
                    StudioNotice(context.s('batchOptionsNote')),
                    const SizedBox(height: 12),
                    StudioNotice(context.s('newCopy'), success: true),
                    if (ready && p.canRun) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: p.running || _saving ? null : () => _save(p),
                        icon: const Icon(Icons.download_outlined),
                        label: Text(context.s('saveResults')),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
