import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictools/l10n/app_localizations.dart';
import 'package:pictools/screens/home_screen.dart';
import 'studio_layout_test.dart' show Rig;

void main() {
  const scenarios = [
    (Size(320, 568), 1.0),
    (Size(360, 740), 1.0),
    (Size(390, 844), 1.0),
    (Size(430, 932), 1.0),
    (Size(740, 360), 1.0),
    (Size(844, 390), 1.0),
    (Size(932, 430), 1.0),
    (Size(768, 1024), 1.0),
    (Size(1366, 768), 1.0),
    (Size(390, 844), 1.4),
    (Size(390, 844), 2.0),
    (Size(320, 568), 2.0),
  ];
  for (final (size, scale) in scenarios) {
    final desktop = size.width >= 1024;
    testWidgets(
      'home cards stay equal at $size / text scale $scale',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final rig = Rig();
        addTearDown(rig.dispose);

        for (final locale in AppLocalizations.supportedLocales) {
          await tester.pumpWidget(
            rig.build(
              const HomeScreen(),
              size: size,
              scale: scale,
              locale: locale,
              padding: desktop
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 24),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$locale');

          Size? cardSize;
          for (final icon in [
            Icons.compare,
            Icons.crop,
            Icons.wb_sunny_outlined,
            Icons.transform,
            if (desktop) Icons.auto_fix_high,
          ]) {
            final card = find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(InkWell),
            );
            expect(card, findsOneWidget);
            final bounds = tester.getRect(card);
            cardSize ??= bounds.size;
            expect(
              bounds.width,
              closeTo(cardSize.width, .01),
              reason: '$locale',
            );
            expect(
              bounds.height,
              closeTo(cardSize.height, .01),
              reason: '$locale',
            );

            // Check the rendered text, including cards below the scroll viewport.
            final labels = find.descendant(
              of: card,
              matching: find.byType(RichText),
            );
            for (final element in labels.evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(paragraph.didExceedMaxLines, isFalse, reason: '$locale');
              final textBounds = tester.getRect(find.byWidget(element.widget));
              expect(bounds.contains(textBounds.topLeft), isTrue);
              expect(bounds.contains(textBounds.bottomRight), isTrue);
            }
          }
        }
      },
      variant: TargetPlatformVariant({
        desktop ? TargetPlatform.macOS : TargetPlatform.android,
      }),
    );
  }
}
