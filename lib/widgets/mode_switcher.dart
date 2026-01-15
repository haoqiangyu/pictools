import 'package:flutter/material.dart';
import '../models/comparison_mode.dart';
import '../theme/app_theme.dart';

/// 模式切换器组件 (固定高度)
class ModeSwitcher extends StatelessWidget {
  final ComparisonMode currentMode;
  final ValueChanged<ComparisonMode>? onModeChanged;
  final double overlayOpacity;
  final ValueChanged<double>? onOpacityChanged;

  const ModeSwitcher({
    super.key,
    required this.currentMode,
    this.onModeChanged,
    this.overlayOpacity = 0.5,
    this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // 固定高度，防止跳动
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 模式按钮
          ...ComparisonMode.values.map(
            (mode) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _ModeButton(
                mode: mode,
                isSelected: currentMode == mode,
                onTap: () => onModeChanged?.call(mode),
              ),
            ),
          ),
          // 透明度滑块 (始终占位，仅在叠加模式时可见)
          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: AppTheme.borderColor),
          const SizedBox(width: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: currentMode == ComparisonMode.overlay ? 1.0 : 0.3,
            child: IgnorePointer(
              ignoring: currentMode != ComparisonMode.overlay,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '透明度',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: overlayOpacity,
                        min: 0,
                        max: 1,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(overlayOpacity * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模式按钮
class _ModeButton extends StatefulWidget {
  final ComparisonMode mode;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeButton({required this.mode, required this.isSelected, this.onTap});

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
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
            color: widget.isSelected
                ? AppTheme.accentColor
                : _isHovering
                ? AppTheme.accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.accentColor
                  : _isHovering
                  ? AppTheme.accentColor.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(widget.mode),
                size: 16,
                color: widget.isSelected
                    ? Colors.white
                    : _isHovering
                    ? AppTheme.accentColor
                    : AppTheme.secondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.mode.displayName,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : _isHovering
                      ? AppTheme.accentColor
                      : AppTheme.textColor,
                  fontSize: 13,
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

  IconData _getIcon(ComparisonMode mode) {
    switch (mode) {
      case ComparisonMode.slider:
        return Icons.compare_arrows;
      case ComparisonMode.sideBySide:
        return Icons.view_column;
      case ComparisonMode.overlay:
        return Icons.layers;
    }
  }
}
