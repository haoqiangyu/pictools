import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

/// 日志面板组件
class LogPanel extends StatefulWidget {
  final List<LogEntry> logs;
  final VoidCallback? onClear;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandChanged;

  const LogPanel({
    super.key,
    required this.logs,
    this.onClear,
    this.isExpanded = true,
    this.onExpandChanged,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final ScrollController _scrollController = ScrollController();
  int _previousLogCount = 0;

  @override
  void didUpdateWidget(LogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当有新日志时自动滚动到底部
    if (widget.logs.length > _previousLogCount && widget.isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousLogCount = widget.logs.length;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.info:
        return AppTheme.secondaryColor;
      case LogType.request:
        return AppTheme.accentColor;
      case LogType.response:
        return AppTheme.highlightColor;
      case LogType.error:
        return AppTheme.errorColor;
    }
  }

  IconData _getLogIcon(LogType type) {
    switch (type) {
      case LogType.info:
        return Icons.info_outline;
      case LogType.request:
        return Icons.upload_outlined;
      case LogType.response:
        return Icons.download_outlined;
      case LogType.error:
        return Icons.error_outline;
    }
  }

  String _getLogTypeLabel(LogType type) {
    switch (type) {
      case LogType.info:
        return 'INFO';
      case LogType.request:
        return 'REQ';
      case LogType.response:
        return 'RES';
      case LogType.error:
        return 'ERR';
    }
  }

  void _copyLogContent(LogEntry log) {
    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
    final content = '[$timeStr] [${_getLogTypeLabel(log.type)}] ${log.message}';
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('日志已复制'),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          InkWell(
            onTap: () => widget.onExpandChanged?.call(!widget.isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.terminal,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '日志',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.logs.length}',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.logs.isNotEmpty)
                    _ClearButton(onTap: widget.onClear),
                ],
              ),
            ),
          ),
          // 日志内容
          if (widget.isExpanded) ...[
            Container(height: 1, color: AppTheme.borderColor),
            Expanded(
              child: widget.logs.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无日志',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: widget.logs.length,
                      itemBuilder: (context, index) {
                        final log = widget.logs[index];
                        return _buildLogItem(log);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final color = _getLogColor(log.type);
    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return GestureDetector(
      onDoubleTap: () => _copyLogContent(log),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间和类型在一行
            Row(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getLogIcon(log.type), size: 10, color: color),
                      const SizedBox(width: 2),
                      Text(
                        _getLogTypeLabel(log.type),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 日志内容 - 可选中复制
            SelectableText(
              log.message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 清除按钮
class _ClearButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _ClearButton({this.onTap});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 12,
                color: _isHovering
                    ? AppTheme.errorColor
                    : AppTheme.secondaryColor,
              ),
              const SizedBox(width: 2),
              Text(
                '清除',
                style: TextStyle(
                  color: _isHovering
                      ? AppTheme.errorColor
                      : AppTheme.secondaryColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
