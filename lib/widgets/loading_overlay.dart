import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 加载遮罩层组件
///
/// 显示一个半透明的遮罩层，中间有加载动画和可选的消息文本。
/// 使用方式：包裹在 Stack 中，或使用 LoadingOverlay.show() 方法。
class LoadingOverlay extends StatefulWidget {
  /// 是否显示遮罩层
  final bool isLoading;

  /// 加载时显示的消息
  final String? message;

  /// 子组件
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();

  /// 显示全局加载对话框
  static Future<T> showWhile<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String? message,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.primaryBg.withValues(alpha: 0.8),
      builder: (context) => _LoadingDialog(message: message),
    );

    try {
      final result = await task();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _LoadingContent(message: widget.message),
          ),
      ],
    );
  }
}

/// 加载对话框
class _LoadingDialog extends StatelessWidget {
  final String? message;

  const _LoadingDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: _LoadingCard(message: message));
  }
}

/// 加载内容区域（用于 overlay 模式）
class _LoadingContent extends StatelessWidget {
  final String? message;

  const _LoadingContent({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBg.withValues(alpha: 0.8),
      child: Center(child: _LoadingCard(message: message)),
    );
  }
}

/// 加载卡片（共用组件）
class _LoadingCard extends StatelessWidget {
  final String? message;

  const _LoadingCard({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 自定义加载动画
          const _PulseLoader(),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 脉冲加载动画
class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 外圈脉冲
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: 1.0 - _opacityAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentColor, width: 2),
                    ),
                  ),
                ),
              ),
              // 内圈
              Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentColor.withValues(alpha: 0.3),
                        AppTheme.accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: AppTheme.accentColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
