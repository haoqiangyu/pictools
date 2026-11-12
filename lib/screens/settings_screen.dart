import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_provider.dart';
import '../layout/studio_scaffold.dart';
import '../l10n/studio_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/studio_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.isStandaloneWindow = false});
  final bool isStandaloneWindow;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return StudioScaffold(
      title: context.s('settings'),
      isStandaloneWindow: widget.isStandaloneWindow,
      body: StudioReadingPane(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioSection(
                    context.s('appearance'),
                    child: StudioSegments<ThemeMode>(
                      items: {
                        ThemeMode.system: context.s('systemTheme'),
                        ThemeMode.light: context.s('lightTheme'),
                        ThemeMode.dark: context.s('darkTheme'),
                      },
                      value: settings.themeMode,
                      onChanged: settings.setThemeMode,
                    ),
                  ),
                  const SizedBox(height: 28),
                  StudioSection(
                    context.s('language'),
                    child: DropdownButtonFormField<String>(
                      initialValue: settings.language ?? 'system',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.s('languageHint'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(context.s('systemLanguage')),
                        ),
                        for (final e in const {
                          'zh_CN': '简体中文',
                          'zh_TW': '繁體中文',
                          'en': 'English',
                          'es': 'Español',
                          'fr': 'Français',
                          'de': 'Deutsch',
                        }.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (value) => settings.setLanguage(
                        value == 'system' ? null : value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: context.studio.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        Icons.shield_outlined,
                        color: context.studio.success,
                      ),
                      title: Text(context.s('privacy')),
                      subtitle: Text(context.s('privacyHint')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pushNamed(context, '/privacy-policy'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/brand/app-icon.png',
                        width: 72,
                        height: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pictools',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<PackageInfo>(
                    future: _info,
                    builder: (context, s) => Text(
                      s.hasData
                          ? '${context.s('version')} ${s.data!.version} (${s.data!.buildNumber})'
                          : context.s('localProcessing'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.studio.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.s('homeFootnote'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.studio.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
