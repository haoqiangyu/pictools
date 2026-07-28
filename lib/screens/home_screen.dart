import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';
import '../models/tool_item.dart';
import '../widgets/tool_card.dart';
import '../services/platform_capabilities.dart';
import '../l10n/app_localizations.dart';

/// 工具集合入口首页
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题栏
              _buildHeader(context),
              const SizedBox(height: 32),
              // 工具网格
              Expanded(child: _buildToolsGrid(context)),
            ],
          ),
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
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // macOS 窗口按钮占位
            if (Platform.isMacOS) const SizedBox(width: 54),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pictools',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.l10n.t('tagline'),
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.l10n.t('settings'),
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryColor,
                backgroundColor: AppTheme.cardBg,
                padding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度计算列数
        final tools = Tools.available;
        const double minCardWidth = 240;
        const double maxCardWidth = 360;
        const double spacing = 20;

        int crossAxisCount = (constraints.maxWidth / (minCardWidth + spacing))
            .floor();
        crossAxisCount = crossAxisCount.clamp(1, 4);

        double cardWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
            crossAxisCount;
        cardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.2,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return ToolCard(
              tool: tool,
              onTap: () => Navigator.of(context).pushNamed(tool.routeName),
            );
          },
        );
      },
    );
  }
}
