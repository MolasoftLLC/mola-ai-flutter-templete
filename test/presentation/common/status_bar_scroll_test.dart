import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status bar scrolls only the visible tab and respects a modal', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    final controllers = List.generate(2, (_) => ScrollController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
    var index = 0;
    late StateSetter update;
    Widget page(int i) => PrimaryScrollController(
      automaticallyInheritForPlatforms: const <TargetPlatform>{},
      controller: controllers[i],
      child: Scaffold(
        appBar: AppBar(title: Text('Page $i')),
        body: ListView.builder(
          controller: controllers[i],
          itemExtent: 60,
          itemCount: 100,
          itemBuilder: (_, item) => Text('$item'),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return IndexedStack(index: index, children: [page(0), page(1)]);
          },
        ),
      ),
    );
    for (final controller in controllers) {
      controller.jumpTo(900);
    }
    await tester.pump();
    Future<void> tapStatusBar() async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.statusBar.name,
        const JSONMethodCodec().encodeMethodCall(
          const MethodCall('handleScrollToTop'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
    }

    await tapStatusBar();
    expect(controllers[0].offset, 0);
    expect(controllers[1].offset, 900);
    update(() => index = 1);
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Page 1'));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Modal')),
    );
    await tester.pumpAndSettle();
    await tapStatusBar();
    expect(controllers[1].offset, 900);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await tapStatusBar();
    expect(controllers[1].offset, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
