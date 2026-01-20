import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/tool_item.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';

/// 工具卡片组件
class ToolCard extends StatefulWidget {
  final ToolItem tool;
  final VoidCallback onTap;

  const ToolCard({super.key, required this.tool, required this.onTap});

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  void _openInNewWindow() {
    final windowType = WindowArguments.fromRouteName(widget.tool.routeName);
    WindowService.instance.openInNewWindow(windowType);
  }

  void _showContextMenu(TapDownDetails details) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      items: [
        PopupMenuItem<String>(
          onTap: widget.onTap,
          child: const Row(
            children: [
              Icon(Icons.open_in_browser, size: 18, color: AppTheme.textColor),
              SizedBox(width: 8),
              Text(
                '在当前窗口打开',
                style: TextStyle(color: AppTheme.textColor, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: _openInNewWindow,
          child: const Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: AppTheme.accentColor),
              SizedBox(width: 8),
              Text(
                '在新窗口打开',
                style: TextStyle(color: AppTheme.accentColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: _showContextMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.cardBg.withValues(alpha: 0.9)
                : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppTheme.accentColor : AppTheme.borderColor,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          transform: _isHovered
              ? Matrix4.translationValues(0, -4, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标 + 新窗口按钮
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.tool.icon,
                      color: AppTheme.accentColor,
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  // 新窗口打开按钮
                  if (_isHovered)
                    Tooltip(
                      message: '在新窗口打开',
                      child: IconButton(
                        onPressed: _openInNewWindow,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 工具名称
              Text(
                widget.tool.name,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // 描述
              Text(
                widget.tool.description,
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
