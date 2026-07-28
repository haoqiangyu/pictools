import 'package:flutter/material.dart';
import '../models/aspect_ratio.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// 裁剪比例选择器组件
class AspectRatioSelector extends StatelessWidget {
  final AspectRatioPreset currentRatio;
  final ValueChanged<AspectRatioPreset>? onRatioChanged;

  const AspectRatioSelector({
    super.key,
    required this.currentRatio,
    this.onRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            context.l10n.t('cropRatio'),
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AspectRatioPreset.values.map((ratio) {
              final isSelected = currentRatio == ratio;
              return _RatioButton(
                label: ratio.displayName,
                isSelected: isSelected,
                onTap: () => onRatioChanged?.call(ratio),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RatioButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RatioButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_RatioButton> createState() => _RatioButtonState();
}

class _RatioButtonState extends State<_RatioButton> {
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
                : AppTheme.primaryBg,
            borderRadius: BorderRadius.circular(8),
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
              fontSize: 13,
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
