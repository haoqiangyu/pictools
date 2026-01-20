import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/ai_image_provider.dart';
import '../services/settings_provider.dart';
import '../services/gemini_service.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/log_panel.dart';
import '../widgets/loading_overlay.dart';
import '../src/rust/api/image_codec.dart';

/// AI 图片修改页面
class AIImageScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const AIImageScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<AIImageScreen> createState() => _AIImageScreenState();
}

class _AIImageScreenState extends State<AIImageScreen> {
  final _promptController = TextEditingController();
  bool _logExpanded = true;

  static const String _geminiDocsUrl = 'https://ai.google.dev/gemini-api/docs';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final aiProvider = context.read<AIImageProvider>();
      if (settingsProvider.hasApiKey) {
        aiProvider.initializeGemini(settingsProvider.geminiApiKey!);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _openGeminiDocs() async {
    final uri = Uri.parse(_geminiDocsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<AIImageProvider>(
                  builder: (context, provider, _) {
                    if (!provider.hasImage) {
                      return _buildUploadSection(context, provider);
                    }
                    return _buildMainContent(context, provider);
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
    return Consumer<AIImageProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            // 返回按钮（独立窗口显示关闭，主窗口显示返回）
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
                Icons.auto_awesome,
                color: AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 图片修改',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '使用 Gemini AI 根据提示词修改图片',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 分离窗口按钮（仅在主窗口显示）
            if (!widget.isStandaloneWindow)
              Tooltip(
                message: '分离到新窗口',
                child: IconButton(
                  onPressed: () async {
                    final success = await WindowService.instance
                        .detachToNewWindow(WindowType.aiImage);
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
            // Gemini 文档链接
            TextButton.icon(
              onPressed: _openGeminiDocs,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('API 文档'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            if (provider.hasImage)
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
        );
      },
    );
  }

  Widget _buildUploadSection(BuildContext context, AIImageProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // API Key 检查
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              if (!settingsProvider.hasApiKey) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '请先在设置中配置 Gemini API Key',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                        child: const Text('去设置'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(
            width: 400,
            height: 300,
            child: ImageUploadArea(
              label: '选择图片',
              onImageSelected: (data, name, path) {
                provider.setImage(data, name: name, path: path);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AIImageProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧：图片预览区
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
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    child: _buildImagePanel(
                      label: '生成结果',
                      imageData: provider.resultData,
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
          width: 340,
          child: Column(
            children: [
              // 图片信息
              _buildInfoPanel(provider),
              const SizedBox(height: 12),
              // 参数设置
              Expanded(child: _buildParameterPanel(provider)),
              const SizedBox(height: 12),
              // 生成按钮
              _buildActionPanel(context, provider),
              const SizedBox(height: 12),
              // 导出按钮
              if (provider.hasResult) ...[
                _buildExportPanel(context, provider),
                const SizedBox(height: 12),
              ],
              // 日志面板
              SizedBox(
                height: 180,
                child: LogPanel(
                  logs: provider.logs,
                  isExpanded: _logExpanded,
                  onExpandChanged: (expanded) {
                    setState(() => _logExpanded = expanded);
                  },
                  onClear: () => provider.clearLogs(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePanel({
    required String label,
    Uint8List? imageData,
    bool isProcessing = false,
    String? errorMessage,
  }) {
    return Stack(
      children: [
        if (imageData != null)
          Positioned.fill(child: Image.memory(imageData, fit: BoxFit.contain))
        else if (!isProcessing && errorMessage == null)
          const Center(
            child: Text(
              '等待生成',
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
                    'AI 处理中...',
                    style: TextStyle(color: AppTheme.textColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        if (errorMessage != null && !isProcessing)
          Container(
            color: AppTheme.primaryBg.withValues(alpha: 0.7),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
    );
  }

  Widget _buildInfoPanel(AIImageProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image_outlined,
                size: 14,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 6),
              const Text(
                '图片信息',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (provider.originalSize != null)
                Text(
                  '${provider.originalSize!.width.toInt()} × ${provider.originalSize!.height.toInt()}',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 文件名完整显示
          Tooltip(
            message: provider.filePath ?? provider.fileName ?? '',
            child: Text(
              provider.fileName ?? '-',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterPanel(AIImageProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(Icons.tune, size: 14, color: AppTheme.accentColor),
              const SizedBox(width: 6),
              const Text(
                '生成参数',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 模型选择
          _buildParameterRow(label: '模型', child: _buildModelSelector(provider)),
          const SizedBox(height: 10),

          // 提示词输入
          const Text(
            '提示词',
            style: TextStyle(color: AppTheme.secondaryColor, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _promptController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (value) => provider.setPrompt(value),
              style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
              decoration: InputDecoration(
                hintText: '描述你想要的修改效果...',
                hintStyle: TextStyle(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
                hintMaxLines: 1,
                filled: true,
                fillColor: AppTheme.primaryBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.accentColor),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 宽高比和分辨率在一行
          Row(
            children: [
              Expanded(
                child: _buildParameterRow(
                  label: '宽高比',
                  child: _buildChipSelector(
                    value: provider.aspectRatio,
                    options: AIImageProvider.aspectRatioOptions
                        .take(5)
                        .toList(),
                    moreOptions: AIImageProvider.aspectRatioOptions
                        .skip(5)
                        .toList(),
                    onChanged: provider.setAspectRatio,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildParameterRow(
                  label: '分辨率',
                  child: _buildSegmentedButton(
                    value: provider.resolution,
                    options: AIImageProvider.resolutionOptions,
                    onChanged: provider.setResolution,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 11),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildModelSelector(AIImageProvider provider) {
    return PopupMenuButton<GeminiModel>(
      onSelected: provider.setModel,
      offset: const Offset(0, 36),
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      itemBuilder: (context) => GeminiModel.available.map((model) {
        final isSelected = provider.selectedModel.id == model.id;
        return PopupMenuItem<GeminiModel>(
          value: model,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.secondaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.alias,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accentColor
                            : AppTheme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      model.id,
                      style: TextStyle(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                provider.selectedModel.alias,
                style: const TextStyle(color: AppTheme.textColor, fontSize: 11),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required String value,
    required List<String> options,
    required List<String> moreOptions,
    required ValueChanged<String> onChanged,
  }) {
    final allOptions = [...options, ...moreOptions];
    final showingMore = !options.contains(value) && moreOptions.contains(value);
    final displayOptions = showingMore ? allOptions.take(5).toList() : options;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayOptions.map((option) {
          final isSelected = value == option;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentColor : AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentColor
                      : AppTheme.borderColor,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
        if (moreOptions.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: onChanged,
            offset: const Offset(0, 24),
            color: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            itemBuilder: (context) => moreOptions.map((option) {
              final isSelected = value == option;
              return PopupMenuItem<String>(
                value: option,
                height: 32,
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.accentColor
                        : AppTheme.textColor,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: moreOptions.contains(value)
                    ? AppTheme.accentColor
                    : AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moreOptions.contains(value) ? value : '更多',
                    style: TextStyle(
                      color: moreOptions.contains(value)
                          ? Colors.white
                          : AppTheme.secondaryColor,
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: moreOptions.contains(value)
                        ? Colors.white
                        : AppTheme.secondaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegmentedButton({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: options.map((option) {
        final isSelected = value == option;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentColor : AppTheme.primaryBg,
                borderRadius: BorderRadius.horizontal(
                  left: option == options.first
                      ? const Radius.circular(6)
                      : Radius.zero,
                  right: option == options.last
                      ? const Radius.circular(6)
                      : Radius.zero,
                ),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentColor
                      : AppTheme.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionPanel(BuildContext context, AIImageProvider provider) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final canGenerate =
            settingsProvider.hasApiKey &&
            provider.hasImage &&
            provider.prompt.isNotEmpty &&
            !provider.isProcessing;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: ElevatedButton.icon(
            onPressed: canGenerate
                ? () {
                    if (settingsProvider.hasApiKey) {
                      provider.initializeGemini(settingsProvider.geminiApiKey!);
                    }
                    provider.generate();
                  }
                : null,
            icon: provider.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    provider.hasResult ? Icons.refresh : Icons.auto_awesome,
                    size: 18,
                  ),
            label: Text(
              provider.isProcessing
                  ? 'AI 处理中...'
                  : provider.hasResult
                  ? '重新生成'
                  : '开始生成',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.accentColor.withValues(
                alpha: 0.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportPanel(BuildContext context, AIImageProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ElevatedButton.icon(
        onPressed: () => _exportImage(context, provider),
        icon: const Icon(Icons.save_alt, size: 18),
        label: const Text('导出图片'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardBg,
          foregroundColor: AppTheme.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
        ),
      ),
    );
  }

  Future<void> _exportImage(
    BuildContext context,
    AIImageProvider provider,
  ) async {
    if (provider.resultData == null) return;

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '保存图片',
      fileName: _generateFileName(provider),
      allowedExtensions: ['png'],
      type: FileType.custom,
    );

    if (outputPath == null) return;
    if (!outputPath.endsWith('.png')) outputPath = '$outputPath.png';

    try {
      await LoadingOverlay.showWhile(
        context,
        message: '正在导出图片...',
        task: () async {
          final encodedBytes = await encodeImage(
            imageData: provider.resultData!,
            format: const ImageFormat.png(),
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

  String _generateFileName(AIImageProvider provider) {
    final originalName = provider.fileName ?? 'image';
    final baseName = originalName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_ai_$timestamp.png';
  }
}
