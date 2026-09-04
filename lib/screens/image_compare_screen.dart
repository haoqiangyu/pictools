import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/image_compare_provider.dart';
import '../services/window_service.dart';
import '../services/window_arguments.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_area.dart';
import '../widgets/comparison_viewer.dart';
import '../services/platform_capabilities.dart';
import '../widgets/mode_switcher.dart';
import '../l10n/app_localizations.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Landscape phones have very little vertical space. Keep the
            // controls reachable and let the page scroll instead of allowing
            // the comparison area to overlap the mode switcher.
            final isShort = constraints.maxHeight < 600;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                SizedBox(height: isShort ? 8 : 16),
                SizedBox(
                  height: isShort ? 88 : 120,
                  child: _buildUploadSection(context),
                ),
                SizedBox(height: isShort ? 8 : 16),
                Container(height: 1, color: AppTheme.borderColor),
                SizedBox(height: isShort ? 8 : 16),
                if (isShort)
                  SizedBox(height: 140, child: _buildComparisonSection(context))
                else
                  Expanded(child: _buildComparisonSection(context)),
                SizedBox(height: isShort ? 8 : 12),
                _buildModeSwitcher(context),
              ],
            );

            final paddedContent = Padding(
              padding: EdgeInsets.fromLTRB(20, isShort ? 12 : 32, 20, 20),
              child: content,
            );

            return isShort
                ? SingleChildScrollView(child: paddedContent)
                : paddedContent;
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () async {
        if (!PlatformCapabilities.supportsMultiWindow) return;
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
            // macOS 窗口按钮占位（仅在非独立窗口时需要，独立窗口有返回按钮）
            if (Platform.isMacOS && widget.isStandaloneWindow)
              const SizedBox(width: 54),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.t('compareTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.l10n.t('compareSubtitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 分离窗口按钮（仅在主窗口显示）
            if (!widget.isStandaloneWindow &&
                PlatformCapabilities.supportsMultiWindow)
              Tooltip(
                message: context.l10n.t('detach'),
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
                  label: Text(context.l10n.t('reset')),
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
                  label: context.l10n.t('originalA'),
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
                  label: context.l10n.t('comparisonB'),
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
          return _buildEmptyState(context);
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare, size: 56, color: AppTheme.borderColor),
            const SizedBox(height: 12),
            Text(
              context.l10n.t('uploadTwoImages'),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.t('supportedFormats'),
              style: const TextStyle(color: AppTheme.borderColor, fontSize: 12),
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
