import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../services/image_import_service.dart';
import '../services/internal_clipboard_service.dart';
import '../services/platform_capabilities.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';

class StudioNotice extends StatelessWidget {
  const StudioNotice(
    this.text, {
    super.key,
    this.success = false,
    this.error = false,
    this.icon,
  });
  final String text;
  final bool success, error;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: success
          ? context.studio.successSoft
          : error
          ? Theme.of(context).colorScheme.errorContainer
          : context.studio.subtle,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon ??
              (success
                  ? Icons.check_circle_outline
                  : error
                  ? Icons.error_outline
                  : Icons.info_outline),
          size: 20,
          color: success
              ? context.studio.success
              : error
              ? Theme.of(context).colorScheme.error
              : context.studio.muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: success
                  ? context.studio.success
                  : error
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : context.studio.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class StudioSection extends StatelessWidget {
  const StudioSection(this.title, {super.key, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class StudioSegments<T> extends StatelessWidget {
  const StudioSegments({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });
  final Map<T, String> items;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final vertical =
          MediaQuery.textScalerOf(context).scale(16) > 24 ||
          c.maxWidth / items.length < 88;
      final buttons = [
        for (final e in items.entries)
          Semantics(
            selected: e.key == value,
            child: TextButton(
              onPressed: () => onChanged(e.key),
              style: TextButton.styleFrom(
                foregroundColor: context.studio.ink,
                backgroundColor: e.key == value
                    ? context.studio.surface
                    : Colors.transparent,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: e.key == value
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
      ];
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.studio.subtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: buttons,
              )
            : Row(children: [for (final b in buttons) Expanded(child: b)]),
      );
    },
  );
}

String studioError(BuildContext context, Object error) {
  final key = error is FormatException ? error.message : 'imageImportError';
  return context.s(key);
}

void studioMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text), showCloseIcon: true));
}

Future<ImportedImage?> acceptImage(
  BuildContext context,
  PlatformFile file,
) async {
  try {
    final image = await ImageImportService.read(file);
    if (!context.mounted) return null;
    if (image.animated) {
      final accepted = await showStudioDialog<bool>(
        context,
        StudioPrompt(
          title: context.s('animatedTitle'),
          message: context.s('animatedBody'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.s('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.s('firstFrame')),
            ),
          ],
        ),
      );
      if (accepted != true) return null;
      return ImageImportService.firstFrame(image);
    }
    return image;
  } catch (e) {
    if (context.mounted) studioMessage(context, studioError(context, e));
    return null;
  }
}

/// Shared by the home screen, all four mobile tools, and batch add/replace.
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.s('importFrom'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(context.s('photoLibrary')),
          subtitle: Text(context.s('importPhotosHint')),
          key: const ValueKey('import-from-photos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_open),
          title: Text(context.s('files')),
          subtitle: Text(context.s('importFilesHint')),
          key: const ValueKey('import-from-files'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, false),
        ),
        const SizedBox(height: 16),
        Text(
          context.s('localPrivate'),
          style: TextStyle(fontSize: 13, color: context.studio.muted),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.s('cancel')),
        ),
      ],
    ),
  );
}

Future<List<PlatformFile>> pickStudioFiles(
  BuildContext context, {
  bool multiple = false,
}) async {
  bool photos = false;
  if (PlatformCapabilities.isMobile) {
    final source = await showStudioDialog<bool>(
      context,
      const ImageSourceSheet(),
    );
    if (source == null) return [];
    photos = source;
  }
  return ImageImportService.pick(multiple: multiple, photos: photos);
}

Future<ImportedImage?> pickStudioImage(BuildContext context) async {
  try {
    final files = await pickStudioFiles(context);
    if (files.isEmpty || !context.mounted) return null;
    return acceptImage(context, files.first);
  } catch (e) {
    if (context.mounted) studioMessage(context, studioError(context, e));
    return null;
  }
}

class StudioPrompt extends StatelessWidget {
  const StudioPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });
  final String title, message;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: actions,
        ),
      ],
    ),
  );
}

class SessionExit extends StatefulWidget {
  const SessionExit({
    super.key,
    required this.hasSession,
    required this.onDiscard,
    required this.child,
    this.busy = false,
  });
  final bool hasSession;
  final bool busy;
  final VoidCallback onDiscard;
  final Widget child;
  @override
  State<SessionExit> createState() => _SessionExitState();
}

class _SessionExitState extends State<SessionExit> {
  bool _allow = false, _asking = false;
  Future<void> _leave() async {
    if (_asking) return;
    _asking = true;
    final discard = await showStudioDialog<bool>(
      context,
      StudioPrompt(
        title: context.s('leaveTitle'),
        message: context.s('leaveBody'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s('discard')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s('keepSession')),
          ),
        ],
      ),
    );
    _asking = false;
    if (discard == null || !mounted) return;
    if (discard) widget.onDiscard();
    setState(() => _allow = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy && (_allow || !widget.hasSession),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !widget.busy) _leave();
    },
    child: widget.child,
  );
}

class StudioEmpty extends StatefulWidget {
  const StudioEmpty({
    super.key,
    required this.title,
    required this.description,
    required this.onImage,
    this.onPick,
    this.icon = Icons.add_photo_alternate_outlined,
  });
  final String title, description;
  final FutureOr<void> Function(ImportedImage) onImage;
  final Future<void> Function()? onPick;
  final IconData icon;
  @override
  State<StudioEmpty> createState() => _StudioEmptyState();
}

class _StudioEmptyState extends State<StudioEmpty> {
  bool _busy = false, _drag = false;
  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.onPick != null) {
        await widget.onPick!();
      } else {
        final file = await pickStudioImage(context);
        if (file != null && mounted) await widget.onImage(file);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _paste() async {
    final clip = await InternalClipboardService.instance.currentImage();
    if (!mounted) return;
    if (clip == null) {
      studioMessage(context, context.s('clipboardEmpty'));
      return;
    }
    final file = await acceptImage(
      context,
      PlatformFile(
        name: clip.fileName ?? 'image.png',
        size: clip.data.length,
        bytes: clip.data,
      ),
    );
    if (file != null && mounted) await widget.onImage(file);
  }

  @override
  Widget build(BuildContext context) => StudioReadingPane(
    child: DropTarget(
      onDragEntered: (_) => setState(() => _drag = true),
      onDragExited: (_) => setState(() => _drag = false),
      onDragDone: (details) async {
        setState(() => _drag = false);
        if (details.files.isEmpty || _busy) return;
        final f = details.files.first;
        final length = await File(f.path).length();
        if (!context.mounted) return;
        final file = await acceptImage(
          context,
          PlatformFile(name: f.name, size: length, path: f.path),
        );
        if (file != null && mounted) await widget.onImage(file);
      },
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (c.maxHeight - 40).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.studio.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                        border: _drag
                            ? Border.all(
                                color: context.studio.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 36,
                        color: context.studio.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.studio.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _pick,
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(context.s('selectImage')),
                      ),
                    ),
                    if (PlatformCapabilities.isDesktop)
                      TextButton.icon(
                        onPressed: _busy ? null : _paste,
                        icon: const Icon(Icons.content_paste),
                        label: Text(context.s('appClipboard')),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      context.s('localPrivate'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.studio.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class StudioFileTile extends StatelessWidget {
  const StudioFileTile({
    super.key,
    required this.name,
    required this.data,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.label,
  });
  final String name;
  final Uint8List? data;
  final String? subtitle, label;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Material(
    color: context.studio.surface,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: data == null
                    ? ColoredBox(
                        color: context.studio.subtle,
                        child: Icon(Icons.add, color: context.studio.primary),
                      )
                    : Image.memory(
                        data!,
                        fit: BoxFit.cover,
                        cacheWidth: 144,
                        errorBuilder: (_, e, s) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        color: context.studio.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.studio.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

StudioAction? detachAction(
  BuildContext context,
  bool standalone,
  WindowType type,
  Future<Map<String, dynamic>> Function() exportState,
) {
  if (standalone || !PlatformCapabilities.supportsMultiWindow) return null;
  return StudioAction(context.s('detach'), Icons.open_in_new, () async {
    final state = await exportState();
    final success = await WindowService.instance.detachToNewWindow(
      type,
      data: state,
    );
    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        studioMessage(context, context.s('windowError'));
      }
    }
  });
}

void restoreWindow(
  bool standalone,
  Future<void> Function(Map<String, dynamic>) importState,
) {
  if (standalone) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = WindowService.instance.currentArguments?.data;
      if (data != null) importState(data);
    });
  }
}
