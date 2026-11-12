import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../layout/studio_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    ('privacyIntroTitle', 'privacyIntro'),
    ('privacyLocalTitle', 'privacyLocal'),
    ('privacyFilesTitle', 'privacyFiles'),
    ('privacyPrefsTitle', 'privacyPrefs'),
    ('privacyDesktopTitle', 'privacyDesktop'),
    ('privacySharingTitle', 'privacySharing'),
    ('privacyContactTitle', 'privacyContact'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioScaffold(
      title: l10n.t('privacyTitle'),
      body: StudioReadingPane(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  l10n.t('privacyUpdated'),
                  style: TextStyle(color: context.studio.muted),
                ),
                const SizedBox(height: 20),
                for (final section in _sections) ...[
                  Text(
                    l10n.t(section.$1),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t(section.$2),
                    style: TextStyle(color: context.studio.muted, height: 1.55),
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
