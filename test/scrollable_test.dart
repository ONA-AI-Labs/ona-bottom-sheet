import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:ona_bottom_sheet/src/foundation/activity.dart';
import 'package:ona_bottom_sheet/src/foundation/controller.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart';
import 'package:ona_bottom_sheet/src/foundation/model_owner.dart';
import 'package:ona_bottom_sheet/src/gestures/gesture_proxy.dart';
import 'package:ona_bottom_sheet/src/physics/detents.dart';
import 'package:ona_bottom_sheet/src/physics/physics.dart';
import 'package:ona_bottom_sheet/src/scroll/scrollable.dart';
import 'package:ona_bottom_sheet/src/widgets/viewport.dart';

import 'src/auto_dispose.dart';
import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

void main() {
  group('Edge behaviors should not depend on scroll physics', () {
    ({Widget testWidget, OnaSheetController controller}) boilerplate({
      required SheetPhysics sheetPhysics,
      required ScrollPhysics scrollPhysics,
      required SheetOffset initialOffset,
      required SheetDetents detents,
      required double sheetHeight,
      required double contentHeight,
    }) {
      final controller = autoDispose(OnaSheetController());
      final testWidget = OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          controller: controller,
          initialOffset: initialOffset,
          detents: detents,
          scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.always),
          physics: sheetPhysics,
          child: SheetScrollable(
            controller: autoDispose(SheetScrollController()),
            child: SizedBox.fromSize(
              size: Size.fromHeight(sheetHeight),
              child: SingleChildScrollView(
                physics: scrollPhysics,
                child: SizedBox.fromSize(size: Size.fromHeight(contentHeight)),
              ),
            ),
          ),
        ),
      );

      return (testWidget: testWidget, controller: controller);
    }

    testWidgets('BouncingSheetPhysics with ClampingScrollPhysics', (tester) async {
      final env = boilerplate(
        sheetPhysics: const BouncingSheetPhysics(),
        scrollPhysics: const ClampingScrollPhysics(),
        initialOffset: const SheetOffset(1),
        detents: const SheetDetents.single(snap: SheetOffset(1)),
        sheetHeight: 600,
        contentHeight: 1000,
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byId('sheet')).top, 0);

      final sheetTopHistory = <double>[];
      env.controller.addListener(() {
        sheetTopHistory.add(tester.getRect(find.byId('sheet')).top);
      });

      await tester.dragDownward(find.byId('sheet'), deltaY: 100);
      await tester.pumpAndSettle();
      expect(sheetTopHistory.min, 0);
      expect(sheetTopHistory.max, greaterThan(0));
      expect(
        sheetTopHistory,
        fluctuationEquals([1, -1]),
        reason:
            'RawSheet should move downward even if '
            'scroll physics does not allow it',
      );
    });

    testWidgets('ClampingSheetPhysics with BouncingScrollPhysics', (tester) async {
      final env = boilerplate(
        sheetPhysics: const ClampingSheetPhysics(),
        scrollPhysics: const BouncingScrollPhysics(),
        initialOffset: const SheetOffset(1),
        detents: const SheetDetents.single(snap: SheetOffset(1)),
        sheetHeight: 600,
        contentHeight: 1000,
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byId('sheet')).top, 0);

      final sheetTopHistory = <double>[];
      env.controller.addListener(() {
        sheetTopHistory.add(tester.getRect(find.byId('sheet')).top);
      });

      await tester.dragDownward(find.byId('sheet'), deltaY: 100);
      await tester.pumpAndSettle();
      expect(
        sheetTopHistory,
        everyElement(isZero),
        reason:
            'RawSheet should not move even if '
            'scroll physics allows it',
      );
    });

    testWidgets('ClampingSheetPhysics with BouncingScrollPhysics: '
        'when content does not overflow and drag delta is large', (tester) async {
      final env = boilerplate(
        sheetPhysics: const ClampingSheetPhysics(),
        scrollPhysics: const BouncingScrollPhysics(),
        initialOffset: const SheetOffset.absolute(250),
        detents: const SheetDetents(snaps: [SheetOffset.absolute(250), SheetOffset(1)]),
        sheetHeight: 500,
        contentHeight: 500,
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 350, 800, 500));

      final gesture = await tester.startDrag(tester.getCenter(find.byId('sheet')), AxisDirection.up);
      await tester.pump();
      await gesture.moveUpwardBy(100 - kDragSlopDefault);
      await tester.pump();
      await gesture.moveUpwardBy(100);
      await tester.pump();
      await gesture.moveUpwardBy(100);
      await tester.pump();

      expect(
        tester.getRect(find.byId('sheet')),
        const Rect.fromLTWH(0, 100, 800, 500),
        reason: 'RawSheet should not go beyond maxOffset',
      );
    });
  });

  group('Scroll sync test', () {
    ({Widget testWidget, OnaSheetController controller, SheetScrollController scrollController}) boilerplate({
      required SheetOffset initialOffset,
      SheetPhysics physics = const BouncingSheetPhysics(),
    }) {
      final controller = autoDispose(OnaSheetController());
      final scrollController = autoDispose(SheetScrollController());
      final testWidget = OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          controller: controller,
          initialOffset: initialOffset,
          detents: const SheetDetents(snaps: [SheetOffset.absolute(300), SheetOffset.absolute(600)]),
          scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.always),
          physics: physics,
          child: SheetScrollable(
            controller: scrollController,
            child: SizedBox.fromSize(
              size: const Size.fromHeight(600),
              child: SingleChildScrollView(
                key: const Key('scrollable'),
                physics: const BouncingScrollPhysics(),
                child: SizedBox.fromSize(size: const Size.fromHeight(1000)),
              ),
            ),
          ),
        ),
      );

      return (testWidget: testWidget, controller: controller, scrollController: scrollController);
    }

    testWidgets('Drag sheet upward, then start scrolling content upward', (tester) async {
      final env = boilerplate(initialOffset: const SheetOffset.absolute(300));

      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 300);

      final gesture = await tester.startDrag(tester.getCenter(find.byId('sheet')), AxisDirection.up);
      await gesture.moveUpwardBy(150 - kDragSlopDefault);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 150);
      expect(env.scrollController.offset, 0);

      await gesture.moveUpwardBy(150);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      await gesture.moveUpwardBy(50);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 50);

      await gesture.moveUpwardBy(100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 150);
    });

    testWidgets('Scroll content upward, then start over-dragging sheet upward', (tester) async {
      final env = boilerplate(initialOffset: const SheetOffset.absolute(600));
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      env.scrollController.jumpTo(100);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 100);

      final gesture = await tester.startDrag(tester.getCenter(find.byKey(const Key('sheet'))), AxisDirection.down);
      await gesture.moveDownwardBy(50 - kDragSlopDefault);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 50);

      await gesture.moveDownwardBy(50);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      await gesture.moveDownwardBy(50);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 50);
      expect(env.scrollController.offset, 0);

      await gesture.moveDownwardBy(100);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 150);
      expect(env.scrollController.offset, 0);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
    });

    testWidgets('Scroll content upward, then start over-dragging sheet upward', (tester) async {
      final env = boilerplate(
        initialOffset: const SheetOffset.absolute(600),
        physics: const BouncingSheetPhysics(resistance: 0, bounceExtent: 50),
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      env.scrollController.jumpTo(300);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 300);

      final gesture = await tester.startDrag(tester.getCenter(find.byKey(const Key('sheet'))), AxisDirection.up);
      await gesture.moveUpwardBy(100 - kDragSlopDefault);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 400);

      await gesture.moveUpwardBy(50);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, closeTo(-23.7, 0.1));
      expect(env.scrollController.offset, 400);

      await gesture.moveUpwardBy(50);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, closeTo(-30.6, 0.1));
      expect(env.scrollController.offset, 400);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
    });

    testWidgets('Seamless hand-over from momentum scrolling (downward) to sheet bouncing', (tester) async {
      final env = boilerplate(initialOffset: const SheetOffset.absolute(600));
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      await tester.dragUpward(find.byKey(const Key('sheet')), deltaY: 100);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.position.extentBefore, 100);

      final sheetTopHistory = <double>[];
      env.controller.addListener(() {
        sheetTopHistory.add(tester.getRect(find.byKey(const Key('sheet'))).top);
      });
      final scrollOffsetHistory = <double>[];
      env.scrollController.addListener(() {
        scrollOffsetHistory.add(env.scrollController.offset);
      });

      await tester.fling(find.byKey(const Key('sheet')), const Offset(0, 50), 1000);
      await tester.pumpAndSettle();
      expect(env.scrollController.position.extentBefore, 0);
      expect(scrollOffsetHistory, isMonotonicallyDecreasing);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(sheetTopHistory.min, 0);
      expect(sheetTopHistory.max, closeTo(40.6, 0.1));
      // The sheet should bounce only once.
      expect(sheetTopHistory, fluctuationEquals([1, -1]));
    });

    testWidgets('Seamless hand-over from momentum scrolling (upward) to sheet bouncing', (tester) async {
      final env = boilerplate(
        initialOffset: const SheetOffset.absolute(600),
        physics: const BouncingSheetPhysics(resistance: 0, bounceExtent: 50),
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.offset, 0);

      env.scrollController.jumpTo(300);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(env.scrollController.position.extentAfter, 100);

      final sheetTopHistory = <double>[];
      env.controller.addListener(() {
        sheetTopHistory.add(tester.getRect(find.byKey(const Key('sheet'))).top);
      });
      final scrollOffsetHistory = <double>[];
      env.scrollController.addListener(() {
        scrollOffsetHistory.add(env.scrollController.offset);
      });

      await tester.fling(find.byKey(const Key('sheet')), const Offset(0, -50), 1000);
      await tester.pumpAndSettle();
      expect(env.scrollController.position.extentAfter, 0);
      expect(scrollOffsetHistory, isMonotonicallyIncreasing);
      expect(tester.getRect(find.byKey(const Key('sheet'))).top, 0);
      expect(sheetTopHistory.min, closeTo(-13.4, 0.1));
      expect(sheetTopHistory.max, 0);
      // The sheet should bounce only once.
      expect(sheetTopHistory, fluctuationEquals([-1, 1]));
    });
  });

  group('Bouncing motion consistency test', () {
    ({Widget testWidget, OnaSheetController controller, SheetScrollController scrollController}) boilerplate() {
      final controller = autoDispose(OnaSheetController());
      final scrollController = autoDispose(SheetScrollController());
      final testWidget = OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          controller: controller,
          initialOffset: const SheetOffset(1),
          detents: const SheetDetents.single(snap: SheetOffset(1)),
          scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.always),
          physics: const BouncingSheetPhysics(),
          child: SheetScrollable(
            controller: scrollController,
            child: SizedBox.fromSize(
              size: const Size.fromHeight(600),
              child: SingleChildScrollView(child: SizedBox.fromSize(size: const Size.fromHeight(1000))),
            ),
          ),
        ),
      );

      return (testWidget: testWidget, controller: controller, scrollController: scrollController);
    }

    testWidgets('Bouncing motion should be consistent when the sheet is dragged downward', (tester) async {
      const flingSpeed = 1000.0;

      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      expect(tester.getRect(find.byId('sheet')).top, 0);
      expect(env.scrollController.offset, 0);

      final sheetTopHistory = [tester.getRect(find.byId('sheet')).top];
      env.controller.addListener(() {
        sheetTopHistory.add(tester.getRect(find.byId('sheet')).top);
      });
      final scrollOffsetHistory = [env.scrollController.offset];
      env.scrollController.addListener(() {
        scrollOffsetHistory.add(env.scrollController.offset);
      });

      // Scroll upward by 20 pixels, then fling downward by 18 pixels.
      await tester.fling(find.byId('sheet'), const Offset(0, 18), flingSpeed, initialOffset: const Offset(0, -20));
      await tester.pumpAndSettle();
      expect(scrollOffsetHistory, fluctuationEquals([1, -1]));
      expect(scrollOffsetHistory.min, 0);
      expect(scrollOffsetHistory.max, 20);
    });
  });

  group('SheetScrollHandlingBehavior', () {
    ({Widget testWidget, SheetScrollController scrollController}) boilerplate({
      required SheetScrollConfiguration scrollConfiguration,
    }) {
      final scrollController = autoDispose(SheetScrollController());
      final testWidget = OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          initialOffset: const SheetOffset(1),
          detents: const SteplessSheetDetents(),
          scrollConfiguration: scrollConfiguration,
          physics: const BouncingSheetPhysics(),
          child: SheetScrollable(
            controller: scrollController,
            child: SizedBox.fromSize(
              size: const Size.fromHeight(300),
              child: SingleChildScrollView(
                key: const Key('scrollable'),
                physics: const BouncingScrollPhysics(),
                child: SizedBox.fromSize(size: const Size.fromHeight(1000)),
              ),
            ),
          ),
        ),
      );
      return (testWidget: testWidget, scrollController: scrollController);
    }

    testWidgets('always: sheet should move downward when scrollable is overscrolled', (tester) async {
      final env = boilerplate(
        scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.always),
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 0);

      final gesture = await tester.startGesture(tester.getCenter(find.byId('sheet')));
      await gesture.moveDownwardBy(100);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, greaterThan(300));
      expect(env.scrollController.offset, 0);

      await gesture.moveUpwardBy(200);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 100);
    });

    testWidgets('onlyFromTop: sheet should move downward when scrollable is overscrolled '
        'and the scroll starts from the top', (tester) async {
      final env = boilerplate(
        scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop),
      );
      await tester.pumpWidget(env.testWidget);
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 0);

      final gesture = await tester.startGesture(tester.getCenter(find.byId('sheet')));
      await gesture.moveDownwardBy(100);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, greaterThan(300));
      expect(env.scrollController.offset, 0);

      await gesture.moveUpwardBy(200);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 100);
    });

    testWidgets('onlyFromTop: sheet should not move downward when scrollable is '
        'overscrolled but the scroll does not start from the top', (tester) async {
      final env = boilerplate(
        scrollConfiguration: const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop),
      );
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 0);

      await tester.dragUpward(find.byId('scrollable'), deltaY: 100);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, 100);

      final gesture = await tester.startGesture(tester.getCenter(find.byId('sheet')));
      await gesture.moveDownwardBy(200);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byId('sheet')).dy, 300);
      expect(env.scrollController.offset, lessThan(0));
      await gesture.up();
    });
  });

  group('delegateUnhandledOverscrollToChild', () {
    ({Widget testWidget, SheetScrollController scrollController, ValueGetter<double> getSheetTop}) boilerplate({
      required WidgetTesterX tester,
      required SheetScrollConfiguration scrollConfiguration,
      required SheetPhysics sheetPhysics,
      required ScrollPhysics scrollPhysics,
    }) {
      final scrollController = autoDispose(SheetScrollController());
      final testWidget = OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          initialOffset: const SheetOffset(1),
          detents: const SingleSheetDetents(snap: SheetOffset(1)),
          scrollConfiguration: scrollConfiguration,
          physics: sheetPhysics,
          child: SheetScrollable(
            controller: scrollController,
            child: SizedBox.fromSize(
              size: const Size.fromHeight(300),
              child: SingleChildScrollView(
                key: const Key('scrollable'),
                physics: scrollPhysics,
                child: SizedBox.fromSize(size: const Size.fromHeight(1000)),
              ),
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        scrollController: scrollController,
        getSheetTop: () => tester.getTopLeft(find.byId('sheet')).dy,
      );
    }

    testWidgets('when true: ClampingSheetPhysics with BouncingScrollPhsics', (tester) async {
      final env = boilerplate(
        tester: tester,
        scrollConfiguration: const SheetScrollConfiguration(delegateUnhandledOverscrollToChild: true),
        sheetPhysics: const ClampingSheetPhysics(),
        scrollPhysics: const BouncingScrollPhysics(),
      );

      await tester.pumpWidget(env.testWidget);
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);

      final startOffset = tester.getCenter(find.byId('sheet'));
      final gesture = await tester.startDrag(startOffset, AxisDirection.down);
      await tester.pump();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, -1 * kDragSlopDefault);

      const dragDelta = 100.0;
      final expectedScrollOffsetAfterDrag =
          env.scrollController.offset -
          const BouncingScrollPhysics().applyPhysicsToUserOffset(env.scrollController.position, dragDelta);
      await gesture.moveDownwardBy(dragDelta);
      expect(env.getSheetTop(), 300, reason: 'RawSheet should not move');
      expect(
        env.scrollController.offset,
        allOf(lessThan(0), equals(expectedScrollOffsetAfterDrag)),
        reason: 'Scrollable should overscroll',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);
    });

    testWidgets('when true: ClampingSheetPhysics with ClampingScrollPhsics', (tester) async {
      final env = boilerplate(
        tester: tester,
        scrollConfiguration: const SheetScrollConfiguration(delegateUnhandledOverscrollToChild: true),
        sheetPhysics: const ClampingSheetPhysics(),
        scrollPhysics: const ClampingScrollPhysics(),
      );

      final capturedNotifications = <OverscrollNotification>[];
      await tester.pumpWidget(
        NotificationListener<OverscrollNotification>(
          onNotification: (notification) {
            capturedNotifications.add(notification);
            return true;
          },
          child: env.testWidget,
        ),
      );
      await tester.pumpAndSettle();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);

      final startOffset = tester.getCenter(find.byId('sheet'));
      final gesture = await tester.startDrag(startOffset, AxisDirection.down);
      await gesture.moveDownwardBy(100);
      await tester.pump();
      expect(env.getSheetTop(), 300, reason: 'RawSheet should not move');
      expect(env.scrollController.offset, 0, reason: 'Scrollable should not overscroll');
      expect(
        capturedNotifications,
        orderedEquals([
          isA<OverscrollNotification>().having((it) => it.overscroll, 'overscroll', -20),
          isA<OverscrollNotification>().having((it) => it.overscroll, 'overscroll', -100),
        ]),
        reason: 'Scrollable should dispatch overscroll notifications',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);
    });

    testWidgets('when true: BouncingSheetPhysics with BouncingScrollPhsics', (tester) async {
      final env = boilerplate(
        tester: tester,
        scrollConfiguration: const SheetScrollConfiguration(delegateUnhandledOverscrollToChild: true),
        sheetPhysics: const BouncingSheetPhysics(),
        scrollPhysics: const BouncingScrollPhysics(),
      );

      await tester.pumpWidget(env.testWidget);
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);

      final startOffset = tester.getCenter(find.byId('sheet'));
      final gesture = await tester.startDrag(startOffset, AxisDirection.down);
      await gesture.moveDownwardBy(100);
      await tester.pump();
      expect(env.getSheetTop(), greaterThan(300), reason: 'RawSheet should move downward');
      expect(env.scrollController.offset, 0, reason: 'RawSheet should consume the whole overflowed scroll delta');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);
    });

    testWidgets('when false: ClampingSheetPhysics with BouncingScrollPhsics', (tester) async {
      final env = boilerplate(
        tester: tester,
        scrollConfiguration: const SheetScrollConfiguration(delegateUnhandledOverscrollToChild: false),
        sheetPhysics: const ClampingSheetPhysics(),
        scrollPhysics: const BouncingScrollPhysics(),
      );

      await tester.pumpWidget(env.testWidget);
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);

      final startOffset = tester.getCenter(find.byId('sheet'));
      final gesture = await tester.startDrag(startOffset, AxisDirection.down);
      await tester.pump();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);

      await gesture.moveDownwardBy(100);
      expect(env.getSheetTop(), 300, reason: 'RawSheet should not move');
      expect(env.scrollController.offset, 0, reason: 'Scrollable should not overscroll');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(env.getSheetTop(), 300);
      expect(env.scrollController.offset, 0);
    });
  });

  testWidgets('Multiple SheetScrollable allows scrollables to have '
      'independent scroll controllers', (tester) async {
    final scrollController1 = autoDispose(SheetScrollController());
    final scrollController2 = autoDispose(SheetScrollController(initialScrollOffset: 50));

    final testWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: OnaSheetViewport(
        child: _TestSheet(
          key: const Key('sheet'),
          scrollConfiguration: const SheetScrollConfiguration(),
          initialOffset: const SheetOffset.absolute(500),
          detents: const SheetDetents(snaps: [SheetOffset.absolute(500), SheetOffset(1)]),
          child: PageView(
            children: [
              _AlwaysKeepAlive(
                child: SheetScrollable(
                  controller: scrollController1,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox.fromSize(size: const Size.fromHeight(1000), child: const Text('page-1')),
                  ),
                ),
              ),
              _AlwaysKeepAlive(
                child: SheetScrollable(
                  controller: scrollController2,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox.fromSize(size: const Size.fromHeight(1000), child: const Text('page-2')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // RawSheet is initially minimized
    await tester.pumpWidget(testWidget);
    expect(scrollController1.offset, 0);
    expect(find.text('page-1'), findsOneWidget);
    expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 100, 800, 600));

    // Drag sheet upward to expand it
    await tester.dragUpward(find.byId('sheet'), deltaY: 200, includeDragSlop: true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 0, 800, 600));
    expect(scrollController1.offset, 100);

    // Swipe to the second page
    await tester.fling(find.byId('sheet'), const Offset(-50, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('page-1'), findsNothing);
    expect(find.text('page-2'), findsOneWidget);
    expect(scrollController2.offset, 50);
    expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 0, 800, 600));

    // Drag sheet downward to minimize it
    await tester.dragDownward(find.byId('sheet'), deltaY: 150, includeDragSlop: true);
    await tester.pumpAndSettle();
    expect(scrollController2.offset, 0);
    expect(scrollController1.offset, 100, reason: 'Scrolling on the second page should not affect the first page');
    expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 100, 800, 600));

    // Swipe back to the first page
    await tester.fling(find.byId('sheet'), const Offset(50, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('page-1'), findsOneWidget);
    expect(find.text('page-2'), findsNothing);

    // Drag sheet upward again
    await tester.dragUpward(find.byId('sheet'), deltaY: 200, includeDragSlop: true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byId('sheet')), const Rect.fromLTWH(0, 0, 800, 600));
    expect(
      scrollController1.offset,
      200,
      reason:
          'Should be able to drag the sheet and '
          'scroll the first page continuously',
    );
    expect(scrollController2.offset, 0, reason: 'Scrolling on the first page should not affect the second page');
  });
}

class _TestModelConfig extends SheetModelConfig {
  const _TestModelConfig({
    required super.physics,
    required super.detents,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

  final SheetScrollConfiguration scrollConfiguration;

  @override
  _TestModelConfig copyWith({SheetPhysics? physics, SheetDetents? detents, SheetGestureProxyMixin? gestureProxy}) {
    throw UnimplementedError();
  }
}

class _TestModel extends SheetModel<_TestModelConfig> with ScrollAwareSheetModelMixin {
  _TestModel(super.context, super.config, SheetOffset initialOffset) {
    beginActivity(InitialSheetActivity(preferredInitialOffset: initialOffset));
  }

  @override
  SheetScrollConfiguration get scrollConfiguration => config.scrollConfiguration;
}

class _TestSheet extends StatelessWidget {
  const _TestSheet({
    super.key,
    this.controller,
    required this.scrollConfiguration,
    required this.initialOffset,
    required this.detents,
    this.physics = kDefaultSheetPhysics,
    required this.child,
  });

  final OnaSheetController? controller;
  final SheetOffset initialOffset;
  final SheetScrollConfiguration scrollConfiguration;
  final SheetPhysics physics;
  final SheetDetents detents;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      controller: controller,
      factory: (context, config) => _TestModel(context, config, initialOffset),
      config: _TestModelConfig(
        gestureProxy: null,
        physics: physics,
        detents: detents,
        scrollConfiguration: scrollConfiguration,
      ),
      child: BareSheet(child: child),
    );
  }
}

class _AlwaysKeepAlive extends StatefulWidget {
  const _AlwaysKeepAlive({required this.child});

  final Widget child;

  @override
  State<_AlwaysKeepAlive> createState() => _AlwaysKeepAliveState();
}

class _AlwaysKeepAliveState extends State<_AlwaysKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
