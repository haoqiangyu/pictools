import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/tool_item.dart';
import '../widgets/tool_card.dart';

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
              _buildHeader(),
              const SizedBox(height: 32),
              // 工具网格
              Expanded(child: _buildToolsGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pictools',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '图片工具集合',
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度计算列数
        const double minCardWidth = 280;
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
            childAspectRatio: 1.4,
          ),
          itemCount: Tools.all.length,
          itemBuilder: (context, index) {
            final tool = Tools.all[index];
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
