import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/capture_radial_menu.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('fan actions and dismissal at $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final anchor = GlobalKey();
      CaptureAction? result;
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              bottomNavigationBar: SizedBox(
                height: 100,
                child: Center(
                  child: IconButton(
                    key: anchor,
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      result = await showCaptureRadialMenu(
                        context,
                        anchorKey: anchor,
                      );
                      completions++;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final action in CaptureAction.values) {
        await tester.tap(find.byKey(anchor));
        await tester.pumpAndSettle();
        final left = tester.getRect(
          find.byKey(const ValueKey('capture-action-gallery')),
        );
        final top = tester.getRect(
          find.byKey(const ValueKey('capture-action-label')),
        );
        final right = tester.getRect(
          find.byKey(const ValueKey('capture-action-menu')),
        );
        expect(left.left, greaterThanOrEqualTo(0));
        expect(right.right, lessThanOrEqualTo(width));
        expect(top.top, lessThan(left.top));
        expect(left.center.dx, lessThan(top.center.dx));
        expect(right.center.dx, greaterThan(top.center.dx));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(ValueKey('capture-action-${action.name}')));
        await tester.pumpAndSettle();
        expect(result, action);
      }
      expect(completions, 3);
      await tester.tap(find.byKey(anchor));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('capture-menu-close')));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.tap(find.byKey(anchor));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 100));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(completions, 5);
      expect(find.byType(CaptureRadialMenu), findsNothing);
    });
  }
}
