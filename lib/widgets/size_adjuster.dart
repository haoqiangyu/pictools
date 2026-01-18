import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 尺寸调整面板组件
class SizeAdjuster extends StatefulWidget {
  final int originalWidth;
  final int originalHeight;
  final int targetWidth;
  final int targetHeight;
  final bool lockAspectRatio;
  final ValueChanged<int>? onWidthChanged;
  final ValueChanged<int>? onHeightChanged;
  final VoidCallback? onLockToggle;
  final void Function(int width, int height)? onPresetApplied;

  const SizeAdjuster({
    super.key,
    required this.originalWidth,
    required this.originalHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.lockAspectRatio,
    this.onWidthChanged,
    this.onHeightChanged,
    this.onLockToggle,
    this.onPresetApplied,
  });

  @override
  State<SizeAdjuster> createState() => _SizeAdjusterState();
}

class _SizeAdjusterState extends State<SizeAdjuster> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.targetWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.targetHeight.toString(),
    );
  }

  @override
  void didUpdateWidget(SizeAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetWidth != oldWidget.targetWidth) {
      _widthController.text = widget.targetWidth.toString();
    }
    if (widget.targetHeight != oldWidget.targetHeight) {
      _heightController.text = widget.targetHeight.toString();
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

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
          // 原始尺寸显示
          _buildOriginalSizeInfo(),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 16),

          // 宽高输入区
          Row(
            children: [
              Expanded(
                child: _buildDimensionInput('宽度', _widthController, true),
              ),
              const SizedBox(width: 12),
              _buildLockButton(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDimensionInput('高度', _heightController, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalSizeInfo() {
    return Row(
      children: [
        const Icon(
          Icons.image_outlined,
          size: 16,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '原始尺寸: ${widget.originalWidth} × ${widget.originalHeight}',
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDimensionInput(
    String label,
    TextEditingController controller,
    bool isWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.primaryBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
            suffixText: 'px',
            suffixStyle: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 12,
            ),
          ),
          onSubmitted: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null && intValue > 0) {
              if (isWidth) {
                widget.onWidthChanged?.call(intValue);
              } else {
                widget.onHeightChanged?.call(intValue);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildLockButton() {
    return Tooltip(
      message: widget.lockAspectRatio ? '已锁定比例' : '未锁定比例',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onLockToggle,
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              color: widget.lockAspectRatio
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.primaryBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.lockAspectRatio
                    ? AppTheme.accentColor
                    : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.lockAspectRatio ? Icons.lock : Icons.lock_open,
              size: 18,
              color: widget.lockAspectRatio
                  ? AppTheme.accentColor
                  : AppTheme.secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
