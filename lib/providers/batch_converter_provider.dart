import 'package:flutter/foundation.dart';
import '../models/export_options.dart';
import '../models/save_destination.dart';
import '../services/image_import_service.dart';
import '../services/image_processing_service.dart';

enum BatchStatus { pending, processing, ready, saved, failed }

class BatchItem {
  BatchItem(this.source) : id = _nextId++;
  static int _nextId = 0;
  final int id;
  final ImportedImage source;
  BatchStatus status = BatchStatus.pending;
  Uint8List? result;
  ExportOptions? options;
  String? error;
  final Set<SaveDestination> _savedTo = {};
  Set<SaveDestination> get savedTo => Set.unmodifiable(_savedTo);
  bool canSaveTo(SaveDestination destination) =>
      result != null &&
      !_savedTo.contains(destination) &&
      (destination == SaveDestination.files || options!.format.supportsPhotos);
  String get statusKey => _savedTo.length == 2
      ? 'savedToBoth'
      : _savedTo.isNotEmpty
      ? _savedTo.single.successKey
      : status.name;
  String get outputName {
    final dot = source.name.lastIndexOf('.');
    return '${dot > 0 ? source.name.substring(0, dot) : source.name}_pictools.${options?.format.extension ?? 'png'}';
  }
}

typedef BatchEncoder = Future<Uint8List> Function(Uint8List, ExportOptions);

class BatchConverterProvider extends ChangeNotifier {
  BatchConverterProvider({BatchEncoder? encoder})
    : _encoder = encoder ?? ImageProcessingService.export;
  final BatchEncoder _encoder;
  final List<BatchItem> _items = [];
  List<BatchItem> get items => List.unmodifiable(_items);
  ExportOptions _options = const ExportOptions();
  ExportOptions get options => _options;
  bool _running = false, _cancelled = false, _disposed = false;
  bool get running => _running;
  int get complete => _items.where((i) => i.result != null).length;
  bool get canRun =>
      !_running &&
      _items.any(
        (i) =>
            i.status == BatchStatus.pending || i.status == BatchStatus.failed,
      );
  void setOptions(ExportOptions value) {
    if (_running) return;
    _options = value;
    notifyListeners();
  }

  void add(ImportedImage image) {
    if (_items.length >= 50 ||
        _items.fold<int>(0, (n, i) => n + i.source.data.length) +
                image.data.length >
            200 * 1024 * 1024) {
      throw const FormatException('batchLimit');
    }
    _items.add(BatchItem(image));
    notifyListeners();
  }

  void remove(BatchItem item) {
    if (_running) return;
    _items.remove(item);
    notifyListeners();
  }

  Future<void> run({BatchItem? only}) async {
    if (_running) return;
    _running = true;
    _cancelled = false;
    notifyListeners();
    final options = _options;
    for (final item in List<BatchItem>.of(_items)) {
      if (_cancelled || _disposed) break;
      if (only != null && item != only ||
          item.status == BatchStatus.saved ||
          item.status == BatchStatus.ready) {
        continue;
      }
      item.status = BatchStatus.processing;
      item.error = null;
      notifyListeners();
      try {
        final bytes = await _encoder(item.source.data, options);
        if (_disposed) return;
        if (_items.fold<int>(0, (n, i) => n + (i.result?.length ?? 0)) +
                bytes.length >
            128 * 1024 * 1024) {
          throw const FormatException('batchResultLimit');
        }
        item.result = bytes;
        item.options = options;
        item.status = BatchStatus.ready;
      } catch (e) {
        if (_disposed) return;
        item.status = BatchStatus.failed;
        item.error = e is FormatException ? e.message : 'exportError';
      }
      notifyListeners();
    }
    if (_disposed) return;
    _running = false;
    notifyListeners();
  }

  void cancel() {
    _cancelled = true;
    notifyListeners();
  }

  bool get cancelling => _cancelled && _running;
  void markSaved(
    BatchItem item, [
    SaveDestination destination = SaveDestination.files,
  ]) {
    if (_disposed || !_items.contains(item) || item.result == null) return;
    item._savedTo.add(destination);
    item.status = BatchStatus.saved;
    notifyListeners();
  }

  void clear() {
    _cancelled = true;
    if (_running) return;
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelled = true;
    super.dispose();
  }
}
