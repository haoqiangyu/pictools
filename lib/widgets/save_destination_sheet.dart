import 'package:flutter/material.dart';
import '../models/save_destination.dart';
import '../l10n/studio_localizations.dart';
import '../layout/studio_scaffold.dart';
import '../services/photo_library_service.dart';
import 'studio_widgets.dart';

Future<SaveDestination?> chooseSaveDestination(
  BuildContext context, {
  required int photoCount,
  required int fileCount,
  required int totalCount,
}) {
  if (!PhotoLibraryService.available) {
    return Future.value(SaveDestination.files);
  }
  return showStudioDialog<SaveDestination>(
    context,
    StudioPrompt(
      title: context.s('chooseDestination'),
      message:
          '${context.s('photosFormats')}\n${context.s('photosCompatible')} $photoCount / $totalCount',
      actions: [
        FilledButton.icon(
          onPressed: photoCount == 0
              ? null
              : () => Navigator.pop(context, SaveDestination.photos),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text('${context.s('saveToPhotos')} · $photoCount'),
        ),
        OutlinedButton.icon(
          onPressed: fileCount == 0
              ? null
              : () => Navigator.pop(context, SaveDestination.files),
          icon: const Icon(Icons.folder_outlined),
          label: Text('${context.s('saveToFiles')} · $fileCount'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.s('cancel')),
        ),
      ],
    ),
  );
}
