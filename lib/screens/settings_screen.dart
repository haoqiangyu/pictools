import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import '../services/platform_capabilities.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.isStandaloneWindow = false});

  final bool isStandaloneWindow;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '-';

  static const _languages = <(String?, String)>[
    (null, 'systemLanguage'),
    ('zh_CN', '简体中文'),
    ('zh_TW', '繁體中文'),
    ('en', 'English'),
    ('es', 'Español'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
  ];

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _section(
                      title: l10n.t('language'),
                      icon: Icons.language_rounded,
                      child: Consumer<SettingsProvider>(
                        builder: (context, settings, _) =>
                            DropdownButtonFormField<String>(
                              initialValue: settings.language ?? 'system',
                              dropdownColor: AppTheme.cardBg,
                              decoration: InputDecoration(
                                labelText: l10n.t('languageHint'),
                                border: const OutlineInputBorder(),
                              ),
                              items: _languages.map((entry) {
                                final value = entry.$1 ?? 'system';
                                final label = entry.$1 == null
                                    ? l10n.t(entry.$2)
                                    : entry.$2;
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (value) => settings.setLanguage(
                                value == null || value == 'system'
                                    ? null
                                    : value,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: l10n.t('privacy'),
                      icon: Icons.privacy_tip_outlined,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('privacy')),
                        subtitle: Text(l10n.t('privacyHint')),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            Navigator.pushNamed(context, '/privacy-policy'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: l10n.t('about'),
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          _infoRow(l10n.t('version'), _version),
                          const Divider(height: 24),
                          _infoRow(l10n.t('localProcessing'), 'Pictools'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onDoubleTap: () async {
        if (!PlatformCapabilities.supportsMultiWindow) return;
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Row(
        children: [
          if (Platform.isMacOS && widget.isStandaloneWindow)
            const SizedBox(width: 54),
          if (!widget.isStandaloneWindow)
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: l10n.t('back'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.settings_rounded, color: AppTheme.accentColor),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('settings'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.t('settingsSubtitle'),
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryColor),
        ),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ],
  );
}
