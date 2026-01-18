import 'package:flutter/material.dart';
import '../models/adjust_mode.dart';
import '../theme/app_theme.dart';

/// 调整模式切换器组件
class AdjustModeSwitcher extends StatelessWidget {
  final AdjustMode currentMode;
  final ValueChanged<AdjustMode>? onModeChanged;

  const AdjustModeSwitcher({
    super.key,
    required this.currentMode,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AdjustMode.values.map((mode) {
          final isSelected = currentMode == mode;
          return _ModeTab(
            label: mode.displayName,
            icon: mode == AdjustMode.resize ? Icons.aspect_ratio : Icons.crop,
            isSelected: isSelected,
            onTap: () => onModeChanged?.call(mode),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_ModeTab> createState() => _ModeTabState();
}

class _ModeTabState extends State<_ModeTab> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.accentColor
                : _isHovering
                ? AppTheme.accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected
                    ? Colors.white
                    : _isHovering
                    ? AppTheme.accentColor
                    : AppTheme.secondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : _isHovering
                      ? AppTheme.accentColor
                      : AppTheme.textColor,
                  fontSize: 14,
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
