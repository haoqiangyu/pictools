import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/background_removal_provider.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../services/model_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/image_panel_with_menu.dart';
import '../widgets/model_download_dialog.dart';
import '../src/rust/api/background_removal.dart' as bg_removal;
import '../src/rust/api/image_codec.dart';
import '../models/export_format.dart';
import '../services/platform_capabilities.dart';

/// 背景移除功能页面
class BackgroundRemovalScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const BackgroundRemovalScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<BackgroundRemovalScreen> createState() =>
      _BackgroundRemovalScreenState();
}

class _BackgroundRemovalScreenState extends State<BackgroundRemovalScreen> {
  final _modelManager = ModelManager();

  @override
  void initState() {
    super.initState();
    // 如果是独立窗口，尝试恢复状态
    if (widget.isStandaloneWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = WindowService.instance.currentArguments;
        if (args?.data != null) {
          context.read<BackgroundRemovalProvider>().importState(args!.data!);
        }
      });
    }

    // 检查模型是否已下载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackgroundRemovalProvider>().checkModelDownloaded();
    });
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
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<BackgroundRemovalProvider>(
                  builder: (context, provider, _) {
                    if (!provider.hasImage) {
                      return _buildUploadSection(context, provider);
                    }
                    return _buildProcessSection(context, provider);
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
    return Consumer<BackgroundRemovalProvider>(
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
                if (!widget.isStandaloneWindow)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    Icons.auto_fix_high,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主体抠图',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '智能抠图去背景，支持PNG透明导出',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!widget.isStandaloneWindow &&
                    provider.hasImage &&
                    PlatformCapabilities.supportsMultiWindow)
                  Tooltip(
                    message: '分离到新窗口',
                    child: IconButton(
                      onPressed: () async {
                        final state = await provider.exportState();
                        final success = await WindowService.instance
                            .detachToNewWindow(
                              WindowType.backgroundRemoval,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadSection(
    BuildContext context,
    BackgroundRemovalProvider provider,
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

  Widget _buildProcessSection(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧：对比预览区
        Expanded(
          flex: 3,
          child: Container(
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
                      label: '原图',
                      imageData: provider.originalData,
                      fileName: provider.fileName,
                      filePath: provider.filePath,
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    child: _buildImagePanel(
                      label: '抠图结果',
                      imageData: provider.hasBackgroundFilled
                          ? provider.backgroundFilledData
                          : provider.resultData,
                      isProcessing: provider.isProcessing,
                      errorMessage: provider.errorMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // 右侧：控制面板
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildInfoPanel(provider),
                const SizedBox(height: 16),
                _buildModelPanel(context, provider),
                const SizedBox(height: 16),
                _buildActionPanel(context, provider),
                if (provider.hasResult) ...[
                  const SizedBox(height: 16),
                  _buildBackgroundPanel(context, provider),
                  const SizedBox(height: 16),
                  _buildExportPanel(context, provider),
                ],
              ],
            ),
          ),
        ),
      ],
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
          if (imageData != null)
            Positioned.fill(child: Image.memory(imageData, fit: BoxFit.contain))
          else if (!isProcessing && errorMessage == null)
            const Center(
              child: Text(
                '等待处理',
                style: TextStyle(color: AppTheme.secondaryColor, fontSize: 14),
              ),
            ),
          if (isProcessing)
            Container(
              color: AppTheme.primaryBg.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.accentColor,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '正在处理...',
                      style: TextStyle(color: AppTheme.textColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildInfoPanel(BackgroundRemovalProvider provider) {
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
          const Text(
            '图片信息',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('文件名', provider.fileName ?? '-'),
          const SizedBox(height: 8),
          _buildInfoRow(
            '尺寸',
            provider.originalSize != null
                ? '${provider.originalSize!.width.toInt()} × ${provider.originalSize!.height.toInt()}'
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool enableCopy = false}) {
    Widget valueWidget = Text(
      value,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
      textAlign: TextAlign.right,
      overflow: enableCopy ? null : TextOverflow.ellipsis,
    );

    if (enableCopy) {
      valueWidget = InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已复制到剪贴板'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: Tooltip(message: '点击复制', child: valueWidget),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: valueWidget),
        ),
      ],
    );
  }

  Widget _buildModelPanel(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) {
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
          const Text(
            '模型选择',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('当前模型', provider.selectedPrecision.displayName),
          _buildInfoRow('状态', provider.isModelDownloaded ? '已下载' : '未下载'),
          if (provider.modelPath != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('路径', provider.modelPath!, enableCopy: true),
          ],
          if (!provider.isModelDownloaded) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showModelDownloadDialog(context, provider),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('下载模型'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionPanel(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) {
    final canProcess = provider.isModelDownloaded && !provider.isProcessing;

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
          const Text(
            '主体抠图',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '使用AI智能识别主体并移除背景',
            style: TextStyle(color: AppTheme.secondaryColor, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: canProcess
                ? () => _processImage(context, provider)
                : null,
            icon: Icon(
              provider.hasResult ? Icons.refresh : Icons.auto_fix_high,
              size: 18,
            ),
            label: Text(provider.hasResult ? '重新处理' : '开始抠图'),
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

  Widget _buildBackgroundPanel(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) {
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
          const Text(
            '背景填充',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BackgroundColor.presets.map((bgColor) {
              final isSelected = provider.backgroundColor == bgColor.color;
              return _ColorButton(
                color: bgColor.color,
                name: bgColor.name,
                isSelected: isSelected,
                onTap: () => _applyBackground(context, provider, bgColor.color),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showColorPicker(context, provider),
                  icon: const Icon(Icons.palette, size: 16),
                  label: const Text('自定义颜色'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                  ),
                ),
              ),
              if (provider.backgroundColor != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => provider.clearBackground(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('清除背景'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportPanel(
    BuildContext context,
    BackgroundRemovalProvider provider,
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

  Future<void> _showModelDownloadDialog(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ModelDownloadDialog(initialPrecision: provider.selectedPrecision),
    );

    if (result != null && mounted) {
      provider.checkModelDownloaded();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('模型下载完成！'),
            backgroundColor: AppTheme.highlightColor,
          ),
        );
      }
    }
  }

  Future<void> _processImage(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) async {
    if (provider.originalData == null) return;

    provider.startProcessing();

    try {
      final modelPath = await _modelManager.getModelPath(
        provider.selectedPrecision,
      );
      final result = await bg_removal.removeBackground(
        imageData: provider.originalData!,
        modelPath: modelPath,
      );
      provider.setResult(result);
    } catch (e) {
      provider.setError('抠图失败: $e');
    }
  }

  Future<void> _applyBackground(
    BuildContext context,
    BackgroundRemovalProvider provider,
    Color color,
  ) async {
    if (provider.resultData == null) return;

    provider.setBackgroundColor(color);

    try {
      final result = await bg_removal.addSolidBackground(
        rgbaData: provider.resultData!,
        bgRed: (color.r * 255.0).round().clamp(0, 255),
        bgGreen: (color.g * 255.0).round().clamp(0, 255),
        bgBlue: (color.b * 255.0).round().clamp(0, 255),
      );
      provider.setBackgroundFilled(result);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('填充背景失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showColorPicker(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) async {
    Color selectedColor = provider.backgroundColor ?? Colors.white;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择背景颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => selectedColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyBackground(context, provider, selectedColor);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportImage(
    BuildContext context,
    BackgroundRemovalProvider provider,
  ) async {
    Uint8List? dataToExport;

    // 确定要导出的数据
    if (provider.hasBackgroundFilled) {
      dataToExport = provider.backgroundFilledData;
    } else if (provider.hasResult) {
      // JPG不支持透明度，需要提示
      if (provider.exportFormat == ExportFormat.jpg &&
          provider.backgroundColor == null) {
        if (context.mounted) {
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('提示'),
              content: const Text('JPG格式不支持透明度，建议添加纯色背景或选择PNG格式导出。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('添加白色背景'),
                ),
              ],
            ),
          );

          if (shouldContinue == true && context.mounted) {
            await _applyBackground(context, provider, Colors.white);
            return; // 重新调用导出
          }
          return;
        }
      }
      dataToExport = provider.resultData;
    }

    if (dataToExport == null) return;

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '保存图片',
      fileName: _generateFileName(provider),
      allowedExtensions: [provider.exportFormat.extension],
      type: FileType.custom,
    );

    if (outputPath == null) return;
    if (!context.mounted) return;

    if (!outputPath.endsWith('.${provider.exportFormat.extension}')) {
      outputPath = '$outputPath.${provider.exportFormat.extension}';
    }

    try {
      await LoadingOverlay.showWhile(
        context,
        message: '正在导出图片...',
        task: () async {
          // 使用 Rust 编码最终格式
          final rustFormat = provider.exportFormat.toRustFormat();

          final encodedBytes = await encodeImage(
            imageData: dataToExport!,
            format: rustFormat,
          );

          final file = File(outputPath!);
          await file.writeAsBytes(encodedBytes);
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存至: $outputPath'),
            backgroundColor: AppTheme.highlightColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _generateFileName(BackgroundRemovalProvider provider) {
    final originalName = provider.fileName ?? 'image';
    final baseName = originalName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return '${baseName}_no_bg.${provider.exportFormat.extension}';
  }
}

class _ColorButton extends StatefulWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected || _isHovering
                ? widget.color.withValues(alpha: 0.2)
                : AppTheme.primaryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : _isHovering
                  ? widget.color.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
