import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictools/widgets/crop_overlay.dart';

void main() {
  testWidgets('full-size crop corner has a touch-friendly drag target', (
    WidgetTester tester,
  ) async {
    Rect changedRect = const Rect.fromLTWH(0, 0, 1, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: CropOverlay(
              imageSize: const Size(300, 300),
              cropRect: changedRect,
              onCropRectChanged: (rect) => changedRect = rect,
            ),
          ),
        ),
      ),
    );

    final overlay = find.byType(CropOverlay);
    final start = tester.getTopLeft(overlay) + const Offset(20, 20);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(30, 30));
    await gesture.up();
    await tester.pump();

    expect(changedRect.left, greaterThan(0));
    expect(changedRect.top, greaterThan(0));
    expect(changedRect.right, 1);
    expect(changedRect.bottom, 1);
  });
}
