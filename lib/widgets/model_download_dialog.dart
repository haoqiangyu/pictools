import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/model_manager.dart';
import '../theme/app_theme.dart';

/// 模型下载对话框
class ModelDownloadDialog extends StatefulWidget {
  final ModelPrecision initialPrecision;

  const ModelDownloadDialog({
    super.key,
    this.initialPrecision = ModelPrecision.fp16,
  });

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  late ModelPrecision _selectedPrecision;
  bool _isDownloading = false;
  bool _isPaused = false;
  DownloadProgress? _progress;
  String? _errorMessage;
  String? _downloadedPath;
  final _tokenController = TextEditingController();
  bool _showTokenInput = false;

  final _modelManager = ModelManager();

  @override
  void initState() {
    super.initState();
    _selectedPrecision = widget.initialPrecision;
    _loadToken();
  }

  Future<void> _loadToken() async {
    await _modelManager.loadHuggingFaceToken();
    final token = _modelManager.huggingFaceToken;
    if (token != null) {
      _tokenController.text = token;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下载模型',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '选择并下载 RMBG-2.0 模型',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isDownloading)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // HuggingFace Token输入
            if (!_isDownloading && _downloadedPath == null) ...[
              _buildTokenSection(),
              const SizedBox(height: 16),
            ],

            // 模型选择
            if (!_isDownloading && _downloadedPath == null) ...[
              const Text(
                '选择模型精度',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...ModelPrecision.values.map((precision) {
                final isSelected = _selectedPrecision == precision;
                final isRecommended = precision == ModelPrecision.fp16;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ModelOption(
                    precision: precision,
                    isSelected: isSelected,
                    isRecommended: isRecommended,
                    onTap: () => setState(() => _selectedPrecision = precision),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // 下载进度
            if (_isDownloading) ...[
              _buildProgressSection(),
              const SizedBox(height: 24),
            ],

            // 错误信息
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 成功信息
            if (_downloadedPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.highlightColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.highlightColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.highlightColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '模型下载完成！',
                        style: TextStyle(
                          color: AppTheme.highlightColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isDownloading && _downloadedPath == null) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('开始下载'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (_isDownloading) ...[
                  if (!_isPaused)
                    TextButton.icon(
                      onPressed: _pauseDownload,
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('暂停'),
                    ),
                  if (_isPaused)
                    ElevatedButton.icon(
                      onPressed: _resumeDownload,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('继续'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _cancelDownload,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('取消'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
                if (_downloadedPath != null)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_downloadedPath),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.highlightColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '正在下载 ${_selectedPrecision.displayName}',
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_progress != null)
              Text(
                '${_progress!.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress != null ? _progress!.percentage / 100 : 0,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor,
            ),
            minHeight: 8,
          ),
        ),
        if (_progress != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_progress!.receivedMB} MB / ${_progress!.totalMB} MB',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_progress!.speedMBps} MB/s',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTokenSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: AppTheme.accentColor, size: 16),
              const SizedBox(width: 6),
              const Text(
                'HuggingFace Token',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showTokenInput = !_showTokenInput),
                icon: Icon(
                  _showTokenInput ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                ),
                label: Text(_showTokenInput ? '收起' : '展开'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (_showTokenInput) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                hintText: '输入您的 HuggingFace Token',
                hintStyle: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppTheme.primaryBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.accentColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  onPressed: () async {
                    final token = _tokenController.text.trim();
                    await _modelManager.setHuggingFaceToken(
                      token.isEmpty ? null : token,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Token已保存'),
                          backgroundColor: AppTheme.highlightColor,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  tooltip: '保存Token',
                ),
              ),
              style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.secondaryColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '下载需要 HuggingFace Token。',
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 10,
                      ),
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://huggingface.co/settings/tokens',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: const Text(
                              '获取Token',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 10,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _isPaused = false;
      _errorMessage = null;
      _progress = null;
    });

    try {
      final path = await _modelManager.downloadModel(
        _selectedPrecision,
        onProgress: (progress) {
          if (mounted && !_isPaused) {
            setState(() => _progress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadedPath = path;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isDownloading = false;
          _isPaused = false;
        });
      }
    }
  }

  void _pauseDownload() {
    _modelManager.cancelDownload();
    setState(() {
      _isPaused = true;
      _isDownloading = false;
    });
  }

  void _resumeDownload() {
    // 重新开始下载（会自动断点续传）
    _startDownload();
  }

  void _cancelDownload() {
    _modelManager.cancelDownload();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// 模型选项卡片
class _ModelOption extends StatefulWidget {
  final ModelPrecision precision;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _ModelOption({
    required this.precision,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  State<_ModelOption> createState() => _ModelOptionState();
}

class _ModelOptionState extends State<_ModelOption> {
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.accentColor.withValues(alpha: 0.1)
                : _isHovering
                ? AppTheme.borderColor.withValues(alpha: 0.3)
                : AppTheme.primaryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.accentColor
                  : _isHovering
                  ? AppTheme.borderColor.withValues(alpha: 0.7)
                  : AppTheme.borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 选择指示器
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.accentColor
                        : AppTheme.borderColor,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 模型信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.precision.displayName,
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (widget.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.highlightColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '推荐',
                              style: TextStyle(
                                color: AppTheme.highlightColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '约 ${(widget.precision.approximateSize / (1024 * 1024)).toStringAsFixed(0)} MB',
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
