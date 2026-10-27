import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('Drag Configuration Test', () {
    Widget boilerplate({required SheetDragConfiguration dragConfiguration}) {
      return OnaSheetViewport(
        child: OnaBottomSheet(
          key: const Key('sheet'),
          initialOffset: const SheetOffset(1),
          detents: const SheetDetents(snaps: [SheetOffset.absolute(100), SheetOffset(1)]),
          dragConfiguration: dragConfiguration,
          child: SizedBox.fromSize(size: const Size.fromHeight(300)),
        ),
      );
    }

    testWidgets('OnaBottomSheet is draggable when dragConfiguration is explicitly provided', (tester) async {
      await tester.pumpWidget(boilerplate(dragConfiguration: const SheetDragConfiguration()));
      expect(tester.getRect(find.byId('sheet')).top, 300);

      await tester.fling(find.byId('sheet'), const Offset(0, 50), 1000);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byId('sheet')).top,
        500,
        reason: 'OnaBottomSheet should have snapped to the lower snap point',
      );
    });

    testWidgets('OnaBottomSheet is not draggable when dragConfiguration is disabled', (tester) async {
      await tester.pumpWidget(boilerplate(dragConfiguration: SheetDragConfiguration.disabled));
      expect(tester.getRect(find.byId('sheet')).top, 300);

      await tester.fling(
        find.byId('sheet'),
        const Offset(0, 50),
        1000,
        // The sheet shouldn't even receive gesture events.
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 300, reason: 'OnaBottomSheet should not have moved');
    });

    testWidgets('Child widgets are still interactive when drag is disabled', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OnaSheetViewport(
            child: OnaBottomSheet(
              dragConfiguration: SheetDragConfiguration.disabled,
              child: SizedBox(
                height: 300,
                child: Material(
                  child: Center(
                    child: ElevatedButton(onPressed: () => tapCount++, child: const Text('Tap me')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapCount, 1);
    });

    testWidgets('Scrollable widgets are still scrollable when drag is disabled', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        OnaSheetViewport(
          child: OnaBottomSheet(
            dragConfiguration: SheetDragConfiguration.disabled,
            child: SizedBox(
              height: 300,
              child: SingleChildScrollView(
                key: const Key('scrollable'),
                controller: scrollController,
                child: const SizedBox(width: double.infinity, height: 1000),
              ),
            ),
          ),
        ),
      );
      expect(scrollController.offset, 0);

      await tester.fling(find.byId('scrollable'), const Offset(0, -200), 1000);
      await tester.pumpAndSettle();
      expect(scrollController.offset, greaterThan(200), reason: 'Scrollable should have scrolled');
    });
  });

  group('deviceKinds', () {
    Widget boilerplate({required SheetDragConfiguration dragConfiguration}) {
      return OnaSheetViewport(
        child: OnaBottomSheet(
          key: const Key('sheet'),
          initialOffset: const SheetOffset(1),
          detents: const SheetDetents(snaps: [SheetOffset.absolute(100), SheetOffset(1)]),
          dragConfiguration: dragConfiguration,
          child: SizedBox.fromSize(size: const Size.fromHeight(300)),
        ),
      );
    }

    testWidgets('Overrides inherited ScrollBehavior.dragDevices if specified', (tester) async {
      await tester.pumpWidget(
        ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.touch}),
          child: boilerplate(dragConfiguration: const SheetDragConfiguration(deviceKinds: {PointerDeviceKind.mouse})),
        ),
      );
      expect(tester.getRect(find.byId('sheet')).top, 300);

      await tester.drag(find.byId('sheet'), const Offset(0, 150), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 500, reason: 'OnaBottomSheet should have moved with mouse drag');

      await tester.drag(find.byId('sheet'), const Offset(0, -150), kind: PointerDeviceKind.touch);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byId('sheet')).top,
        500,
        reason: 'OnaBottomSheet should not have moved with touch drag',
      );
    });

    testWidgets('Falls back to inherited ScrollBehavior.dragDevices if not specified', (tester) async {
      await tester.pumpWidget(
        ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse}),
          child: boilerplate(dragConfiguration: const SheetDragConfiguration(deviceKinds: null)),
        ),
      );
      expect(tester.getRect(find.byId('sheet')).top, 300);

      await tester.drag(find.byId('sheet'), const Offset(0, 150), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byId('sheet')).top, 500, reason: 'OnaBottomSheet should have moved with mouse drag');

      await tester.drag(find.byId('sheet'), const Offset(0, -150), kind: PointerDeviceKind.touch);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byId('sheet')).top,
        500,
        reason: 'OnaBottomSheet should not have moved with touch drag',
      );
    });
  });

  group('Initial Build Layout Test', () {
    testWidgets('detents is respected on first build with multiple snap points', (tester) async {
      await tester.pumpWidget(
        OnaSheetViewport(
          child: OnaBottomSheet(
            key: const Key('sheet'),
            initialOffset: const SheetOffset(0.2),
            detents: const SheetDetents(snaps: [SheetOffset(0.5), SheetOffset(1)]),
            child: SizedBox.fromSize(size: const Size.fromHeight(600)),
          ),
        ),
      );
      expect(
        tester.getRect(find.byId('sheet')),
        const Rect.fromLTWH(0, 300, 800, 600),
        reason: 'OnaBottomSheet should snap to nearest snap point (offset=0.5)',
      );
    });

    testWidgets('initialOffset within detents is preserved', (tester) async {
      await tester.pumpWidget(
        OnaSheetViewport(
          child: OnaBottomSheet(
            key: const Key('sheet'),
            initialOffset: const SheetOffset(0.2),
            detents: const SheetDetents(snaps: [SheetOffset(0.2), SheetOffset(1)]),
            child: SizedBox.fromSize(size: const Size.fromHeight(600)),
          ),
        ),
      );
      expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 480, 800, 600));
    });
  });
}
