import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/image_compare_provider.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/comparison_viewer.dart';
import '../widgets/mode_switcher.dart';

/// 图片对比功能页面
class ImageCompareScreen extends StatefulWidget {
  final bool isStandaloneWindow;

  const ImageCompareScreen({super.key, this.isStandaloneWindow = false});

  @override
  State<ImageCompareScreen> createState() => _ImageCompareScreenState();
}

class _ImageCompareScreenState extends State<ImageCompareScreen> {
  @override
  void initState() {
    super.initState();
    // 如果是独立窗口，尝试恢复状态
    if (widget.isStandaloneWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = WindowService.instance.currentArguments;
        if (args?.data != null) {
          context.read<ImageCompareProvider>().importState(args!.data!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部标题栏
              _buildHeader(context),
              const SizedBox(height: 16),
              // 图片上传区域
              _buildUploadSection(context),
              const SizedBox(height: 16),
              // 分割线
              Container(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 16),
              // 对比区域
              Expanded(child: _buildComparisonSection(context)),
              const SizedBox(height: 12),
              // 模式切换器
              _buildModeSwitcher(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      behavior: HitTestBehavior.translucent, // 确保空白区域也能响应
      child: Container(
        color: Colors.transparent, // 必须设置颜色(即使是透明)才能响应点击
        width: double.infinity, // 占满横向空间
        padding: const EdgeInsets.symmetric(vertical: 8), // 增加一点垂直点击区域
        child: Row(
          children: [
            // 返回按钮
            if (!widget.isStandaloneWindow)
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_rounded),
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
                Icons.compare,
                color: AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '图片对比',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '对比两张图片，清晰展示差异',
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
                    // 导出当前状态
                    final state = await context
                        .read<ImageCompareProvider>()
                        .exportState();
                    final success = await WindowService.instance
                        .detachToNewWindow(
                          WindowType.imageCompare,
                          data: state,
                        );
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
            Consumer<ImageCompareProvider>(
              builder: (context, provider, _) {
                if (!provider.hasBothImages) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: () => provider.reset(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重置'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return Consumer<ImageCompareProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 120,
          child: Row(
            children: [
              // 图片 A 上传区域
              Expanded(
                child: ImageUploadArea(
                  label: '原图 A',
                  imageData: provider.imageA,
                  fileName: provider.imageAName,
                  filePath: provider.imageAPath,
                  onImageSelected: (data, name, path) {
                    provider.setImageA(data, name: name, path: path);
                  },
                  onClear: () => provider.clearImageA(),
                ),
              ),
              const SizedBox(width: 12),
              // 图片 B 上传区域
              Expanded(
                child: ImageUploadArea(
                  label: '对比图 B',
                  imageData: provider.imageB,
                  fileName: provider.imageBName,
                  filePath: provider.imageBPath,
                  onImageSelected: (data, name, path) {
                    provider.setImageB(data, name: name, path: path);
                  },
                  onClear: () => provider.clearImageB(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonSection(BuildContext context) {
    return Consumer<ImageCompareProvider>(
      builder: (context, provider, _) {
        if (!provider.hasBothImages) {
          return _buildEmptyState();
        }

        return ComparisonViewer(
          imageA: provider.imageA!,
          imageB: provider.imageB!,
          mode: provider.mode,
          sliderPosition: provider.sliderPosition,
          overlayOpacity: provider.overlayOpacity,
          onSliderChanged: (position) {
            provider.setSliderPosition(position);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare, size: 56, color: AppTheme.borderColor),
            SizedBox(height: 12),
            Text(
              '请先上传两张图片进行对比',
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              '支持 PNG, JPG, GIF, WEBP, BMP 格式',
              style: TextStyle(color: AppTheme.borderColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(BuildContext context) {
    return Consumer<ImageCompareProvider>(
      builder: (context, provider, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: provider.hasBothImages ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !provider.hasBothImages,
            child: ModeSwitcher(
              currentMode: provider.mode,
              onModeChanged: (mode) => provider.setMode(mode),
              overlayOpacity: provider.overlayOpacity,
              onOpacityChanged: (opacity) =>
                  provider.setOverlayOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}
