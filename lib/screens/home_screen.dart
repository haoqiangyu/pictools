import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layout/studio_scaffold.dart';
import '../layout/foldable_environment.dart';
import '../l10n/studio_localizations.dart';
import '../providers/image_adjust_provider.dart';
import '../providers/image_compare_provider.dart';
import '../providers/image_enhance_provider.dart';
import '../providers/batch_converter_provider.dart';
import '../services/platform_capabilities.dart';
import '../theme/app_theme.dart';
import '../widgets/studio_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _importing = false;
  Future<void> _startImport() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      await _import(context);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    final image = await pickStudioImage(context);
    if (image == null || !context.mounted) return;
    final route = await showStudioDialog<String>(
      context,
      SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.s('chooseTool'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            StudioFileTile(
              name: image.name,
              data: image.data,
              subtitle: '${image.width} × ${image.height} px',
            ),
            const SizedBox(height: 16),
            for (final t in _tools)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(t.$3, color: context.studio.primary),
                title: Text(context.s(t.$1)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, t.$4),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.s('cancel')),
            ),
          ],
        ),
      ),
    );
    if (route == null || !context.mounted) return;
    switch (route) {
      case '/image-adjust':
        await context.read<ImageAdjustProvider>().setImage(
          image.data,
          name: image.name,
          path: image.path,
        );
      case '/image-compare':
        context.read<ImageCompareProvider>().setImageA(
          image.data,
          name: image.name,
          path: image.path,
        );
      case '/image-enhance':
        await context.read<ImageEnhanceProvider>().setImage(
          image.data,
          name: image.name,
          path: image.path,
        );
      case '/image-converter':
        try {
          context.read<BatchConverterProvider>().add(image);
        } catch (e) {
          if (context.mounted) studioMessage(context, studioError(context, e));
          return;
        }
    }
    if (context.mounted) Navigator.pushNamed(context, route);
  }

  static const _tools = [
    ('compareShort', 'compareHint', Icons.compare, '/image-compare'),
    ('adjustTitle', 'adjustHint', Icons.crop, '/image-adjust'),
    ('enhanceShort', 'enhanceHint', Icons.wb_sunny_outlined, '/image-enhance'),
    ('convertShort', 'convertHint', Icons.transform, '/image-converter'),
  ];
  @override
  Widget build(BuildContext context) {
    final adjust = context.watch<ImageAdjustProvider>(),
        compare = context.watch<ImageCompareProvider>(),
        enhance = context.watch<ImageEnhanceProvider>(),
        batch = context.watch<BatchConverterProvider>();
    final sessions = <Widget>[
      if (adjust.hasImage)
        StudioFileTile(
          name: adjust.fileName ?? context.s('adjustTitle'),
          data: adjust.imageData,
          label: context.s('adjustTitle'),
          onTap: () => Navigator.pushNamed(context, '/image-adjust'),
        ),
      if (compare.imageA != null || compare.imageB != null)
        StudioFileTile(
          name: context.s('compareShort'),
          data: compare.imageA ?? compare.imageB,
          onTap: () => Navigator.pushNamed(context, '/image-compare'),
        ),
      if (enhance.hasImage)
        StudioFileTile(
          name: enhance.fileName ?? context.s('enhanceShort'),
          data: enhance.originalData,
          label: context.s('enhanceShort'),
          onTap: () => Navigator.pushNamed(context, '/image-enhance'),
        ),
      if (batch.items.isNotEmpty)
        StudioFileTile(
          name: '${context.s('queue')} · ${batch.items.length}',
          data: batch.items.first.source.data,
          subtitle: context.s(batch.running ? 'processing' : 'continueEditing'),
          onTap: () => Navigator.pushNamed(context, '/image-converter'),
        ),
    ];
    return StudioScaffold(
      title: 'Pictools',
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset('assets/brand/app-icon.png', width: 32, height: 32),
      ),
      actions: [
        StudioAction(
          context.s('settings'),
          Icons.settings_outlined,
          () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 800;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.s('homeHeadline'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.s('homeDescription'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: context.studio.muted,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _importing ? null : _startImport,
                child: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.s('selectImage')),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, c) {
                  final two =
                      c.maxWidth >= 320 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24;
                  final columns = two ? 2 : 1;
                  final cards = [
                    for (final t in _tools)
                      _ToolCard(
                        title: context.s(t.$1),
                        description: context.s(t.$2),
                        icon: t.$3,
                        route: t.$4,
                      ),
                    if (PlatformCapabilities.supportsBackgroundRemoval)
                      _ToolCard(
                        title: context.s('tool.background_removal.name'),
                        description: context.s('desktopModel'),
                        icon: Icons.auto_fix_high,
                        route: '/background-removal',
                      ),
                  ];
                  // Equal flex rows share the tallest card's natural height,
                  // including wrapped translations and system text scaling.
                  return IntrinsicHeight(
                    child: Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var row = 0; row < cards.length; row += columns)
                          Expanded(
                            child: Row(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var col = 0; col < columns; col++)
                                  Expanded(
                                    child: row + col < cards.length
                                        ? cards[row + col]
                                        : const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: context.studio.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.s('localPrivate'),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.studio.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.s('homeFootnote'),
                style: TextStyle(fontSize: 14, color: context.studio.muted),
              ),
            ],
          );
          final recent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.s('currentSession'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.s('sessionOnly'),
                style: TextStyle(fontSize: 13, color: context.studio.muted),
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                StudioNotice(context.s('noSession'))
              else
                for (final s in sessions)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: s),
            ],
          );
          if ((StudioLayoutScope.of(context)?.divisions ?? []).isNotEmpty) {
            return StudioWorkspace(
              preview: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
              inspector: recent,
              previewFraction: .55,
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 20,
              24,
              wide ? 32 : 20,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: content),
                          const SizedBox(width: 32),
                          SizedBox(width: 300, child: recent),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          content,
                          if (sessions.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            recent,
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
  final String title, description, route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Material(
    color: context.studio.surface,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 126),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.studio.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: context.studio.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
