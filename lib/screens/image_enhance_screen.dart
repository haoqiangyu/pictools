import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/image_enhance_provider.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/image_panel_with_menu.dart';
import '../models/export_format.dart';
import '../services/file_export_service.dart';
import '../services/image_processing_service.dart';
import '../services/platform_capabilities.dart';
import '../l10n/app_localizations.dart';

/// 图片亮度增强功能页面
class ImageEnhanceScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const ImageEnhanceScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<ImageEnhanceScreen> createState() => _ImageEnhanceScreenState();
}

class _ImageEnhanceScreenState extends State<ImageEnhanceScreen> {
  @override
  void initState() {
    super.initState();
    // 如果是独立窗口，尝试恢复状态
    if (widget.isStandaloneWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = WindowService.instance.currentArguments;
        if (args?.data != null) {
          context.read<ImageEnhanceProvider>().importState(args!.data!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部标题栏
              _buildHeader(context),
              const SizedBox(height: 16),
              // 主内容区
              Expanded(
                child: Consumer<ImageEnhanceProvider>(
                  builder: (context, provider, _) {
                    if (!provider.hasImage) {
                      return _buildUploadSection(context, provider);
                    }
                    return _buildPreviewSection(context, provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<ImageEnhanceProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onDoubleTap: () async {
            if (!PlatformCapabilities.supportsMultiWindow) return;
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // 返回按钮
                if (!widget.isStandaloneWindow)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      backgroundColor: AppTheme.cardBg,
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.t('enhanceTitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.l10n.t('enhanceSubtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 分离窗口按钮（仅在主窗口显示）
                if (!widget.isStandaloneWindow &&
                    PlatformCapabilities.supportsMultiWindow)
                  Tooltip(
                    message: context.l10n.t('detach'),
                    child: IconButton(
                      onPressed: () async {
                        // 导出当前状态
                        final state = await context
                            .read<ImageEnhanceProvider>()
                            .exportState();
                        final success = await WindowService.instance
                            .detachToNewWindow(
                              WindowType.imageEnhance,
                              data: state,
                            );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        backgroundColor: AppTheme.cardBg,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                    ),
                  ),
                if (provider.hasImage) ...[
                  PlatformCapabilities.isMobile
                      ? IconButton(
                          onPressed: provider.reset,
                          icon: const Icon(Icons.close),
                          color: AppTheme.errorColor,
                          tooltip: context.l10n.t('clear'),
                        )
                      : TextButton.icon(
                          onPressed: provider.reset,
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(context.l10n.t('clear')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                        ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadSection(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) {
    return Center(
      child: SizedBox(
        width: 400,
        height: 300,
        child: ImageUploadArea(
          label: context.l10n.t('selectImage'),
          onImageSelected: (data, name, path) {
            provider.setImage(data, name: name, path: path);
          },
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) {
    final preview = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(
              child: _buildImagePanel(
                label: context.l10n.t('original'),
                imageData: provider.originalData,
                fileName: provider.fileName,
                filePath: provider.filePath,
              ),
            ),
            Container(width: 1, color: AppTheme.borderColor),
            Expanded(
              child: _buildImagePanel(
                label: context.l10n.t('enhanced'),
                imageData: provider.enhancedData,
                isProcessing: provider.isProcessing,
                errorMessage: provider.errorMessage,
              ),
            ),
          ],
        ),
      ),
    );
    final controls = SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoPanel(provider),
          const SizedBox(height: 12),
          _buildActionPanel(context, provider),
          if (provider.hasEnhanced) ...[
            const SizedBox(height: 12),
            _buildExportPanel(context, provider),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(flex: 5, child: preview),
              const SizedBox(height: 12),
              Expanded(flex: 4, child: controls),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: preview),
            const SizedBox(width: 20),
            SizedBox(width: 280, child: controls),
          ],
        );
      },
    );
  }

  Widget _buildImagePanel({
    required String label,
    Uint8List? imageData,
    String? fileName,
    String? filePath,
    bool isProcessing = false,
    String? errorMessage,
  }) {
    return ImagePanelWithMenu(
      imageData: imageData,
      fileName: fileName ?? '$label.png',
      filePath: filePath,
      child: Stack(
        children: [
          // 图片
          if (imageData != null)
            Positioned.fill(child: Image.memory(imageData, fit: BoxFit.contain))
          else if (!isProcessing && errorMessage == null)
            Center(
              child: Text(
                context.l10n.t('waiting'),
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          // 加载中
          if (isProcessing)
            Container(
              color: AppTheme.primaryBg.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.accentColor,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.t('processing'),
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 错误信息
          if (errorMessage != null)
            Container(
              color: AppTheme.primaryBg.withValues(alpha: 0.7),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          // 标签
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(ImageEnhanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('imageInfo'),
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context.l10n.t('fileName'), provider.fileName ?? '-'),
          const SizedBox(height: 8),
          _buildInfoRow(
            context.l10n.t('dimensions'),
            provider.originalSize != null
                ? '${provider.originalSize!.width.toInt()} × ${provider.originalSize!.height.toInt()}'
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.t('enhanceTitle'),
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('enhanceInfo'),
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: provider.isProcessing
                ? null
                : () => _processImage(context, provider),
            icon: Icon(
              provider.hasEnhanced ? Icons.refresh : Icons.auto_fix_high,
              size: 18,
            ),
            label: Text(
              context.l10n.t(
                provider.hasEnhanced ? 'processAgain' : 'startEnhance',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.accentColor.withValues(
                alpha: 0.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) async {
    if (provider.originalData == null) return;

    final processingFailed = context.l10n.t('processingFailed');
    provider.startProcessing();

    try {
      final result = await ImageProcessingService.enhance(
        provider.originalData!,
      );
      provider.setEnhancedData(result);
    } catch (e) {
      provider.setError(processingFailed.replaceAll('{error}', '$e'));
    }
  }

  Widget _buildExportPanel(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 格式选择
          Row(
            children: [
              Text(
                context.l10n.t('exportFormat'),
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ExportFormat.values.map((format) {
                      final isSelected = provider.exportFormat == format;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FormatButton(
                          label: format.displayName,
                          isSelected: isSelected,
                          onTap: () => provider.setExportFormat(format),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 导出按钮
          ElevatedButton.icon(
            onPressed: () => _exportImage(context, provider),
            icon: const Icon(Icons.save_alt, size: 18),
            label: Text(context.l10n.t('exportImage')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportImage(
    BuildContext context,
    ImageEnhanceProvider provider,
  ) async {
    if (provider.enhancedData == null) return;

    try {
      String? outputPath;
      await LoadingOverlay.showWhile(
        context,
        message: context.l10n.t('exporting'),
        task: () async {
          final encodedBytes = await ImageProcessingService.encode(
            provider.enhancedData!,
            provider.exportFormat,
          );
          outputPath = await FileExportService.save(
            bytes: encodedBytes,
            fileName: _generateFileName(provider),
            extension: provider.exportFormat.extension,
          );
        },
      );

      if (outputPath == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PlatformCapabilities.isMobile
                  ? context.l10n.t('saved')
                  : context.l10n.t('savedTo').replaceAll('{path}', outputPath!),
            ),
            backgroundColor: AppTheme.highlightColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('exportFailed').replaceAll('{error}', '$e'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _generateFileName(ImageEnhanceProvider provider) {
    final originalName = provider.fileName ?? 'image';
    final baseName = originalName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return '${baseName}_enhanced.${provider.exportFormat.extension}';
  }
}

class _FormatButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FormatButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_FormatButton> createState() => _FormatButtonState();
}

class _FormatButtonState extends State<_FormatButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.accentColor
                : _isHovering
                ? AppTheme.accentColor.withValues(alpha: 0.1)
                : AppTheme.primaryBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.accentColor
                  : _isHovering
                  ? AppTheme.accentColor.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? Colors.white
                  : _isHovering
                  ? AppTheme.accentColor
                  : AppTheme.textColor,
              fontSize: 11,
              fontWeight: widget.isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
