import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';
import '../l10n/studio_localizations.dart';
import '../services/platform_capabilities.dart';
import 'foldable_environment.dart';

class StudioAction {
  const StudioAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class StudioScaffold extends StatelessWidget {
  const StudioScaffold({
    super.key,
    required this.title,
    required this.body,
    this.primary,
    this.actions = const [],
    this.onBack,
    this.leading,
    this.isStandaloneWindow = false,
  });
  final String title;
  final Widget body;
  final StudioAction? primary;
  final List<StudioAction> actions;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool isStandaloneWindow;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.padding;
    final divisions = FoldableEnvironment.divisionsOf(context);
    final usableWidth = media.size.width - safe.horizontal;
    final usableHeight =
        media.size.height - safe.vertical - media.viewInsets.bottom;
    final side =
        usableWidth >= 1024 ||
        usableHeight < 500 && usableWidth > 600 ||
        (safe.left >= 40 || safe.right >= 40) && usableHeight > 300;
    final left = side && safe.left > safe.right;
    final rail = side ? 64.0 : 0.0;
    final large = media.textScaler.scale(18) > 24;
    final headerHeight = large ? 80.0 : 64.0;
    final origin = Offset(
      safe.left + (left ? rail : 0),
      safe.top + headerHeight,
    );
    Widget menu() => PopupMenuButton<int>(
      tooltip: context.s('more'),
      icon: const Icon(Icons.more_horiz),
      onSelected: (i) => actions[i].onPressed?.call(),
      itemBuilder: (_) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem(
            value: i,
            enabled: actions[i].onPressed != null,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(actions[i].icon),
              title: Text(actions[i].label),
            ),
          ),
      ],
    );
    final back =
        onBack ??
        (!isStandaloneWindow && Navigator.of(context).canPop()
            ? () => Navigator.of(context).maybePop()
            : null);
    final header = GestureDetector(
      onPanStart: PlatformCapabilities.isDesktop
          ? (_) => windowManager.startDragging()
          : null,
      child: SizedBox(
        height: headerHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (!side && back != null)
                IconButton(
                  tooltip: context.s('back'),
                  onPressed: back,
                  icon: const Icon(Icons.chevron_left),
                ),
              if (leading != null) const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!side && actions.isNotEmpty)
                IconButton(
                  tooltip: actions.first.label,
                  onPressed: actions.first.onPressed,
                  icon: Icon(actions.first.icon),
                ),
              if (!side && actions.length > 1) menu(),
            ],
          ),
        ),
      ),
    );
    final main = Expanded(
      child: Column(
        children: [
          header,
          Expanded(
            child: StudioLayoutScope(
              origin: origin,
              sideControls: side,
              keyboardVisible: media.viewInsets.bottom > 0,
              divisions: divisions,
              child: body,
            ),
          ),
        ],
      ),
    );
    final sidebar = ColoredBox(
      color: context.studio.surface,
      child: SizedBox(
        width: 64,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    if (back != null)
                      IconButton(
                        tooltip: context.s('back'),
                        onPressed: back,
                        icon: const Icon(Icons.chevron_left),
                      ),
                    for (final a in actions.take(1))
                      IconButton(
                        tooltip: a.label,
                        onPressed: a.onPressed,
                        icon: Icon(a.icon),
                      ),
                    const Spacer(),
                    if (primary != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Tooltip(
                          message: primary!.label,
                          child: FilledButton(
                            onPressed: primary!.onPressed,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(48, 56),
                            ),
                            child: Icon(primary!.icon),
                          ),
                        ),
                      ),
                    if (actions.isNotEmpty) menu(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: context.studio.background,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [if (left) sidebar, main, if (side && !left) sidebar],
          ),
        ),
      ),
    );
  }
}

/// Stable child identities preserve text controllers, focus, zoom and scrolling
/// while the same editing session is rearranged around a fold or keyboard.
class StudioWorkspace extends StatefulWidget {
  const StudioWorkspace({
    super.key,
    required this.preview,
    required this.inspector,
    this.primary,
    this.previewFraction = .46,
  });
  final Widget preview, inspector;
  final StudioAction? primary;
  final double previewFraction;
  @override
  State<StudioWorkspace> createState() => _StudioWorkspaceState();
}

class _StudioWorkspaceState extends State<StudioWorkspace> {
  final _previewKey = GlobalKey();
  final _inspectorKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final scope = StudioLayoutScope.of(context);
    final keyboard =
        scope?.keyboardVisible ?? (MediaQuery.viewInsetsOf(context).bottom > 0);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final viewport = Rect.fromLTWH(0, 0, w, h);
        final regions = (scope?.divisions ?? const <Rect>[])
            .map((r) => r.shift(-(scope?.origin ?? Offset.zero)))
            .where(
              (r) =>
                  r.overlaps(viewport) ||
                  r.width == 0 && r.left > 0 && r.left < w ||
                  r.height == 0 && r.top > 0 && r.top < h,
            )
            .toList();
        Rect? fold;
        for (final r in regions) {
          if (w > 320 &&
                  r.height > h * .5 &&
                  r.left > 100 &&
                  r.right < w - 160 ||
              r.width > w * .5 && r.top > 80 && r.top < h && r.bottom > 0) {
            fold = r;
            break;
          }
        }
        Rect preview, inspector;
        if (fold != null && fold.height > fold.width) {
          final start = (fold.left - 12).clamp(100.0, w - 180);
          final end = (fold.right + 12).clamp(start, w - 160);
          preview = Rect.fromLTWH(0, 0, start, h);
          inspector = Rect.fromLTWH(end, 0, w - end, h);
        } else if (fold != null) {
          final start = (fold.top - 12).clamp(0.0, h);
          final end = (fold.bottom + 12).clamp(start, h);
          // If a keyboard consumes the lower pane, put controls in the upper
          // pane instead of moving interactive content across the division.
          if (h - end < 140) {
            inspector = Rect.fromLTWH(0, 0, w, start);
            preview = Rect.fromLTWH(0, end, w, h - end);
          } else {
            preview = Rect.fromLTWH(0, 0, w, start);
            inspector = Rect.fromLTWH(0, end, w, h - end);
          }
        } else if (w >= 720 || w >= 600 && h < 500) {
          final iw = math.min(
            w * .46,
            math.max(296.0, 320.0 * math.min(scale, 1.35)),
          );
          preview = Rect.fromLTWH(0, 0, w - iw, h);
          inspector = Rect.fromLTWH(w - iw, 0, iw, h);
        } else {
          final ph =
              (keyboard
                      ? math.min(104.0, h * .24)
                      : math.min(
                          h * .52,
                          math.max(120.0, h * widget.previewFraction),
                        ))
                  .toDouble();
          preview = Rect.fromLTWH(0, 0, w, ph);
          inspector = Rect.fromLTWH(0, ph, w, h - ph);
        }
        return Stack(
          children: [
            Positioned.fromRect(
              rect: preview,
              child: KeyedSubtree(key: _previewKey, child: widget.preview),
            ),
            Positioned.fromRect(
              rect: inspector,
              child: KeyedSubtree(
                key: _inspectorKey,
                child: Material(
                  color: context.studio.background,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const PageStorageKey('studio-inspector'),
                          padding: const EdgeInsets.all(20),
                          child: widget.inspector,
                        ),
                      ),
                      if (widget.primary != null &&
                          !(scope?.sideControls ?? false))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: widget.primary!.onPressed,
                              icon: Icon(widget.primary!.icon, size: 20),
                              label: Text(widget.primary!.label),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dialogs stay within one active fold region. The content state is retained
/// while geometry changes, including rotation with the export sheet open.
Future<T?> showStudioDialog<T>(BuildContext context, Widget child) =>
    showDialog<T>(
      context: context,
      useSafeArea: false,
      builder: (context) => _AdaptiveDialog(child: child),
    );

class _AdaptiveDialog extends StatelessWidget {
  const _AdaptiveDialog({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context),
        pad = MediaQuery.paddingOf(context),
        keyboard = MediaQuery.viewInsetsOf(context).bottom;
    var area = Rect.fromLTRB(
      pad.left + 12,
      pad.top + 12,
      size.width - pad.right - 12,
      size.height - math.max(pad.bottom, keyboard) - 12,
    );
    for (final f in FoldableEnvironment.divisionsOf(context)) {
      if (f.height > f.width && f.left > area.left && f.right < area.right) {
        area = Rect.fromLTRB(f.right + 12, area.top, area.right, area.bottom);
      } else if (f.width > f.height &&
          f.top > area.top &&
          f.bottom < area.bottom) {
        area = area.bottom - f.bottom >= 200
            ? Rect.fromLTRB(area.left, f.bottom + 12, area.right, area.bottom)
            : Rect.fromLTRB(area.left, area.top, area.right, f.top - 12);
      }
    }
    final width = math.min(440.0, area.width), height = area.height;
    return Stack(
      children: [
        Positioned(
          left: area.center.dx - width / 2,
          top: area.top,
          width: width,
          height: height,
          child: Center(
            child: Material(
              color: context.studio.background,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reading and import surfaces occupy a single usable pane on a divided view.
class StudioReadingPane extends StatelessWidget {
  const StudioReadingPane({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scope = StudioLayoutScope.of(context);
      var area = Rect.fromLTWH(0, 0, c.maxWidth, c.maxHeight);
      for (final region in scope?.divisions ?? const <Rect>[]) {
        final f = region.shift(-(scope?.origin ?? Offset.zero));
        if (f.height > f.width && f.left > 0 && f.right < c.maxWidth) {
          final left = Rect.fromLTRB(
            0,
            0,
            (f.left - 12).clamp(0, c.maxWidth),
            c.maxHeight,
          );
          final right = Rect.fromLTRB(
            (f.right + 12).clamp(0, c.maxWidth),
            0,
            c.maxWidth,
            c.maxHeight,
          );
          area = left.width >= right.width ? left : right;
        } else if (f.width > f.height && f.top > 0 && f.bottom < c.maxHeight) {
          final top = Rect.fromLTRB(
            0,
            0,
            c.maxWidth,
            (f.top - 12).clamp(0, c.maxHeight),
          );
          final bottom = Rect.fromLTRB(
            0,
            (f.bottom + 12).clamp(0, c.maxHeight),
            c.maxWidth,
            c.maxHeight,
          );
          area = top.height >= bottom.height ? top : bottom;
        }
      }
      return Stack(
        children: [Positioned.fromRect(rect: area, child: child)],
      );
    },
  );
}
