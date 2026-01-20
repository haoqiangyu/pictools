import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
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
import 'package:file_picker/file_picker.dart';
import '../src/rust/api/image_codec.dart';
import '../widgets/loading_overlay.dart';

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
          padding: const EdgeInsets.all(20),
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
        return Row(
          children: [
            // 返回按钮
            IconButton(
              onPressed: () {
                if (widget.isStandaloneWindow) {
                  WindowService.instance.closeCurrentWindow();
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(
                widget.isStandaloneWindow
                    ? Icons.close
                    : Icons.arrow_back_rounded,
              ),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '图片调整',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '调整图片尺寸，按比例裁剪',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 分离窗口按钮
            if (!widget.isStandaloneWindow)
              Tooltip(
                message: '分离到新窗口',
                child: IconButton(
                  onPressed: () async {
                    // 导出当前状态
                    final state = await context
                        .read<ImageAdjustProvider>()
                        .exportState();
                    final success = await WindowService.instance
                        .detachToNewWindow(WindowType.imageAdjust, data: state);
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
              TextButton.icon(
                onPressed: () => provider.resetToOriginal(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重置'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => provider.reset(),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('清除'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
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
          label: '选择图片',
          onImageSelected: (data, name, path) {
            provider.setImage(data, name: name, path: path);
          },
        ),
      ),
    );
  }

  Widget _buildEditSection(BuildContext context, ImageAdjustProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧：图片预览区
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: ImagePreview(
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // 右侧：控制面板
        SizedBox(
          width: 320,
          child: Column(
            children: [
              // 模式切换器
              AdjustModeSwitcher(
                currentMode: provider.mode,
                onModeChanged: (mode) => provider.setMode(mode),
              ),
              const SizedBox(height: 16),

              // 根据模式显示不同控制面板
              Expanded(
                child: SingleChildScrollView(
                  child: provider.mode == AdjustMode.resize
                      ? SizeAdjuster(
                          originalWidth:
                              provider.originalSize?.width.toInt() ?? 0,
                          originalHeight:
                              provider.originalSize?.height.toInt() ?? 0,
                          targetWidth: provider.targetWidth,
                          targetHeight: provider.targetHeight,
                          lockAspectRatio: provider.lockAspectRatio,
                          onWidthChanged: (w) => provider.setTargetWidth(w),
                          onHeightChanged: (h) => provider.setTargetHeight(h),
                          onLockToggle: () => provider.toggleLockAspectRatio(),
                          onPresetApplied: (w, h) =>
                              provider.applyPresetSize(w, h),
                        )
                      : AspectRatioSelector(
                          currentRatio: provider.aspectRatio,
                          onRatioChanged: (ratio) =>
                              provider.setAspectRatio(ratio),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 导出面板
              _buildExportPanel(context, provider),
            ],
          ),
        ),
      ],
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
              const Text(
                '导出格式',
                style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
              ),
              const Spacer(),
              ...ExportFormat.values.map((format) {
                final isSelected = provider.exportFormat == format;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _FormatButton(
                    label: format.displayName,
                    isSelected: isSelected,
                    onTap: () => provider.setExportFormat(format),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          // 导出按钮
          ElevatedButton.icon(
            onPressed: () => _exportImage(context, provider),
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('导出图片'),
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
    // 选择保存路径（在 loading 之前，避免被遮挡）
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '保存图片',
      fileName: _generateFileName(provider),
      allowedExtensions: [provider.exportFormat.extension],
      type: FileType.custom,
    );

    if (outputPath == null) return;

    // 确保文件扩展名正确
    if (!outputPath.endsWith('.${provider.exportFormat.extension}')) {
      outputPath = '$outputPath.${provider.exportFormat.extension}';
    }

    try {
      // 使用 loading 遮罩执行耗时操作
      await LoadingOverlay.showWhile(
        context,
        message: '正在导出图片...',
        task: () async {
          // 使用 image 包解码原图
          final originalImage = img.decodeImage(provider.imageData!);
          if (originalImage == null) {
            throw Exception('无法解码图片');
          }

          img.Image resultImage;

          if (provider.mode == AdjustMode.crop) {
            // 裁剪模式
            final cropX = (provider.cropRect.left * originalImage.width)
                .round();
            final cropY = (provider.cropRect.top * originalImage.height)
                .round();
            final cropWidth = (provider.cropRect.width * originalImage.width)
                .round();
            final cropHeight = (provider.cropRect.height * originalImage.height)
                .round();

            resultImage = img.copyCrop(
              originalImage,
              x: cropX,
              y: cropY,
              width: cropWidth,
              height: cropHeight,
            );
          } else {
            // 尺寸调整模式
            resultImage = img.copyResize(
              originalImage,
              width: provider.targetWidth,
              height: provider.targetHeight,
              interpolation: img.Interpolation.cubic,
            );
          }

          // 先将处理后的图片编码为 PNG 作为中间格式传给 Rust
          final pngBytes = Uint8List.fromList(img.encodePng(resultImage));

          // 使用 Rust 编码最终格式
          final ImageFormat rustFormat;
          switch (provider.exportFormat) {
            case ExportFormat.png:
              rustFormat = const ImageFormat.png();
              break;
            case ExportFormat.jpg:
              rustFormat = const ImageFormat.jpg(quality: 95);
              break;
            case ExportFormat.webp:
              rustFormat = const ImageFormat.webP(quality: 90, lossless: false);
              break;
          }

          final encodedBytes = await encodeImage(
            imageData: pngBytes,
            format: rustFormat,
          );

          // 保存文件
          final file = File(outputPath!);
          await file.writeAsBytes(encodedBytes);
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存至: $outputPath'),
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
            content: Text('导出失败: $e'),
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
