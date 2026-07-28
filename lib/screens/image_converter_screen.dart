import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../models/export_format.dart';
import '../services/image_processing_service.dart';
import '../services/platform_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../services/file_export_service.dart';

class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  // 当前处理的文件列表
  final List<ConverterItem> _items = [];

  // 全局输出格式设置
  ExportFormat _globalExportFormat = ExportFormat.png;

  // 是否正在处理
  bool _isProcessing = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _items.add(ConverterItem(path: file.path!, name: file.name));
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _items.clear();
    });
  }

  Future<void> _convertAll() async {
    if (_items.isEmpty) return;

    String? outputDirectory;
    if (!PlatformCapabilities.isMobile) {
      outputDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.l10n.t('chooseSaveFolder'),
      );
      if (outputDirectory == null) return;
    }
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });
    var failedCount = 0;

    try {
      await LoadingOverlay.showWhile(
        context,
        message: context.l10n.t('converting'),
        task: () async {
          for (var item in _items) {
            try {
              final file = File(item.path);
              final bytes = await file.readAsBytes();
              final encodedBytes = await ImageProcessingService.encode(
                bytes,
                _globalExportFormat,
              );

              final dotIndex = item.name.lastIndexOf('.');
              final fileNameWithoutExt = dotIndex > 0
                  ? item.name.substring(0, dotIndex)
                  : item.name;
              final newFileName =
                  '$fileNameWithoutExt.${_globalExportFormat.extension}';
              if (PlatformCapabilities.isMobile) {
                final savedPath = await FileExportService.save(
                  bytes: encodedBytes,
                  fileName: newFileName,
                  extension: _globalExportFormat.extension,
                );
                if (savedPath == null) {
                  throw const FileSystemException('用户取消保存');
                }
              } else {
                final outputPath = '$outputDirectory/$newFileName';
                await File(outputPath).writeAsBytes(encodedBytes, flush: true);
              }

              if (mounted) {
                setState(() => item.status = ConversionStatus.success);
              }
            } catch (_) {
              failedCount++;
              if (mounted) {
                setState(() => item.status = ConversionStatus.failed);
              }
            }
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount == 0
                  ? context.l10n.t('conversionDone')
                  : context.l10n
                        .t('conversionPartial')
                        .replaceAll('{count}', '$failedCount'),
            ),
            backgroundColor: failedCount == 0
                ? AppTheme.highlightColor
                : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('conversionFailed').replaceAll('{error}', '$e'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.primaryBg, // Fixed: backgroundColor -> primaryBg
      appBar: AppBar(
        title: Text(context.l10n.t('converterTitle')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 顶部操作栏
          _buildTopBar(),

          // 文件列表区域
          Expanded(
            child: _items.isEmpty ? _buildEmptyState() : _buildFileList(),
          ),

          // 底部控制栏
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardBg,
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(context.l10n.t('addImages')),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.accentColor, // Fixed: primaryColor -> accentColor
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _items.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep),
            label: Text(context.l10n.t('clearList')),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyState = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.t(
              PlatformCapabilities.isMobile
                  ? 'tapAddImages'
                  : 'dropOrAddImages',
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );

    if (PlatformCapabilities.isMobile) return emptyState;

    return DropTarget(
      onDragDone: (details) {
        setState(() {
          for (final file in details.files) {
            _items.add(ConverterItem(path: file.path, name: file.name));
          }
        });
      },
      child: emptyState,
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppTheme.cardBg,
          child: ListTile(
            leading: const Icon(
              Icons.image,
              color: AppTheme.accentColor,
            ), // Fixed: primaryColor -> accentColor
            title: Text(
              item.name,
              style: const TextStyle(color: AppTheme.textColor),
            ),
            subtitle: Text(
              item.path,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.status == ConversionStatus.success)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.highlightColor,
                  ),
                if (item.status == ConversionStatus.failed)
                  const Icon(Icons.error, color: AppTheme.errorColor),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.secondaryColor),
                  onPressed: () => _removeFile(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            context.l10n.t('outputFormat'),
            style: const TextStyle(color: AppTheme.textColor),
          ),
          const SizedBox(width: 16),
          DropdownButton<ExportFormat>(
            value: _globalExportFormat,
            dropdownColor: AppTheme.cardBg,
            style: const TextStyle(color: AppTheme.textColor),
            underline: Container(height: 1, color: AppTheme.borderColor),
            items: ExportFormat.values.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _globalExportFormat = value;
                });
              }
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _items.isEmpty || _isProcessing ? null : _convertAll,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.accentColor, // Fixed: primaryColor -> accentColor
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.t('startConversion'),
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

enum ConversionStatus { pending, success, failed }

class ConverterItem {
  final String path;
  final String name;
  ConversionStatus status;

  ConverterItem({
    required this.path,
    required this.name,
    this.status = ConversionStatus.pending,
  });
}
