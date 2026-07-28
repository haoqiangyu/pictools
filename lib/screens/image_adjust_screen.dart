import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../models/adjust_mode.dart';
import '../models/aspect_ratio.dart';
import '../providers/image_adjust_provider.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/image_preview.dart';
import '../widgets/adjust_mode_switcher.dart';
import '../widgets/size_adjuster.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/loading_overlay.dart';
import '../models/export_format.dart';
import '../services/file_export_service.dart';
import '../services/image_processing_service.dart';
import '../services/platform_capabilities.dart';
import '../l10n/app_localizations.dart';

/// 图片调整功能页面
class ImageAdjustScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const ImageAdjustScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<ImageAdjustScreen> createState() => _ImageAdjustScreenState();
}

class _ImageAdjustScreenState extends State<ImageAdjustScreen> {
  @override
  void initState() {
    super.initState();
    // 如果是独立窗口，尝试恢复状态
    if (widget.isStandaloneWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = WindowService.instance.currentArguments;
        if (args?.data != null) {
          context.read<ImageAdjustProvider>().importState(args!.data!);
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
                child: Consumer<ImageAdjustProvider>(
                  builder: (context, provider, _) {
                    if (!provider.hasImage) {
                      return _buildUploadSection(context, provider);
                    }
                    return _buildEditSection(context, provider);
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
    return Consumer<ImageAdjustProvider>(
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
                    Icons.crop,
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
                        context.l10n.t('adjustTitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.l10n.t('adjustSubtitle'),
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
                // 分离窗口按钮
                if (!widget.isStandaloneWindow &&
                    PlatformCapabilities.supportsMultiWindow)
                  Tooltip(
                    message: context.l10n.t('detach'),
                    child: IconButton(
                      onPressed: () async {
                        // 导出当前状态
                        final state = await context
                            .read<ImageAdjustProvider>()
                            .exportState();
                        final success = await WindowService.instance
                            .detachToNewWindow(
                              WindowType.imageAdjust,
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
                  if (PlatformCapabilities.isMobile) ...[
                    IconButton(
                      onPressed: provider.resetToOriginal,
                      icon: const Icon(Icons.refresh),
                      color: AppTheme.secondaryColor,
                      tooltip: context.l10n.t('reset'),
                    ),
                    IconButton(
                      onPressed: provider.reset,
                      icon: const Icon(Icons.close),
                      color: AppTheme.errorColor,
                      tooltip: context.l10n.t('clear'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: provider.resetToOriginal,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(context.l10n.t('reset')),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: provider.reset,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(context.l10n.t('clear')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],
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
    ImageAdjustProvider provider,
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

  Widget _buildEditSection(BuildContext context, ImageAdjustProvider provider) {
    final preview = ImagePreview(
      imageData: provider.imageData!,
      showCropOverlay: provider.mode == AdjustMode.crop,
      cropRect: provider.cropRect,
      onCropRectChanged: (rect) => provider.setCropRect(rect),
      aspectRatio: provider.aspectRatio.ratio,
      targetSize: Size(
        provider.targetWidth.toDouble(),
        provider.targetHeight.toDouble(),
      ),
      originalSize: provider.originalSize,
    );
    final controls = Column(
      children: [
        AdjustModeSwitcher(
          currentMode: provider.mode,
          onModeChanged: (mode) => provider.setMode(mode),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: provider.mode == AdjustMode.resize
                ? SizeAdjuster(
                    originalWidth: provider.originalSize?.width.toInt() ?? 0,
                    originalHeight: provider.originalSize?.height.toInt() ?? 0,
                    targetWidth: provider.targetWidth,
                    targetHeight: provider.targetHeight,
                    lockAspectRatio: provider.lockAspectRatio,
                    onWidthChanged: provider.setTargetWidth,
                    onHeightChanged: provider.setTargetHeight,
                    onLockToggle: provider.toggleLockAspectRatio,
                    onPresetApplied: provider.applyPresetSize,
                  )
                : AspectRatioSelector(
                    currentRatio: provider.aspectRatio,
                    onRatioChanged: provider.setAspectRatio,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _buildExportPanel(context, provider),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(flex: 5, child: preview),
              const SizedBox(height: 12),
              Expanded(flex: 6, child: controls),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: preview),
            const SizedBox(width: 20),
            SizedBox(width: 320, child: controls),
          ],
        );
      },
    );
  }

  Widget _buildExportPanel(BuildContext context, ImageAdjustProvider provider) {
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
    ImageAdjustProvider provider,
  ) async {
    try {
      String? outputPath;
      // 使用 loading 遮罩执行耗时操作
      await LoadingOverlay.showWhile(
        context,
        message: context.l10n.t('exporting'),
        task: () async {
          final encodedBytes = provider.mode == AdjustMode.resize
              ? await ImageProcessingService.resizeAndEncode(
                  provider.imageData!,
                  width: provider.targetWidth,
                  height: provider.targetHeight,
                  format: provider.exportFormat,
                )
              : await ImageProcessingService.cropAndEncode(
                  provider.imageData!,
                  left: provider.cropRect.left,
                  top: provider.cropRect.top,
                  width: provider.cropRect.width,
                  height: provider.cropRect.height,
                  format: provider.exportFormat,
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

  String _generateFileName(ImageAdjustProvider provider) {
    final originalName = provider.fileName ?? 'image';
    final baseName = originalName.replaceAll(RegExp(r'\.[^.]+$'), '');

    String suffix;
    if (provider.mode == AdjustMode.crop) {
      // 裁剪模式：显示比例和实际尺寸
      final ratioName = provider.aspectRatio.displayName;
      final cropWidth =
          (provider.cropRect.width * (provider.originalSize?.width ?? 0))
              .round();
      final cropHeight =
          (provider.cropRect.height * (provider.originalSize?.height ?? 0))
              .round();
      suffix = '_${ratioName}_${cropWidth}x$cropHeight';
    } else {
      // 尺寸调整模式：显示目标尺寸
      suffix = '_${provider.targetWidth}x${provider.targetHeight}';
    }

    return '$baseName$suffix.${provider.exportFormat.extension}';
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
