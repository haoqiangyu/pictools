import 'package:flutter/material.dart';
import '../models/comparison_mode.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final modeButtons = ComparisonMode.values
            .map(
              (mode) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _ModeButton(
                  mode: mode,
                  compact: isCompact,
                  isSelected: currentMode == mode,
                  onTap: () => onModeChanged?.call(mode),
                ),
              ),
            )
            .toList();
        final opacityControl = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.t('opacity'),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
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
                style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
              ),
            ),
          ],
        );

        return Container(
          height: isCompact && currentMode == ComparisonMode.overlay ? 106 : 58,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: isCompact
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: modeButtons,
                    ),
                    if (currentMode == ComparisonMode.overlay) ...[
                      const SizedBox(height: 6),
                      Expanded(child: opacityControl),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...modeButtons,
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppTheme.borderColor,
                    ),
                    const SizedBox(width: 16),
                    SizedBox(width: 220, child: opacityControl),
                  ],
                ),
        );
      },
    );
  }
}

/// 模式按钮
class _ModeButton extends StatefulWidget {
  final ComparisonMode mode;
  final bool compact;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.mode,
    required this.compact,
    required this.isSelected,
    this.onTap,
  });

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
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 9 : 14,
            vertical: 8,
          ),
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
