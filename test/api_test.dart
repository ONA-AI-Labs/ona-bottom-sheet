import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';
import 'package:ona_bottom_sheet/src/foundation/double_utils.dart';
import 'package:ona_bottom_sheet/src/foundation/float_comp.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart';

import 'src/auto_dispose.dart';

/// The public value types, the controller and the position-driven animation, as a developer meets them.
void main() {
  group('offsets', () {
    const ImmutableViewportLayout layout = ImmutableViewportLayout(
      viewportSize: Size(400, 1000),
      viewportPadding: EdgeInsets.zero,
      contentSize: Size(400, 600),
      contentMargin: EdgeInsets.zero,
      contentBaseline: 20,
    );

    test('resolve, compare and describe themselves', () {
      expect(const SheetOffset(0.5).resolve(layout), 320);
      expect(const SheetOffset.absolute(100).resolve(layout), 100);
      expect(const SheetOffset.absolute(100, relativeToBaseline: true).resolve(layout), 120);
      expect(const SheetOffset.proportionalToViewport(0.25).resolve(layout), 250);

      expect(const SheetOffset(0.5), const SheetOffset(0.5));
      expect(const SheetOffset(0.5).hashCode, const SheetOffset(0.5).hashCode);
      expect(const SheetOffset.absolute(1), isNot(const SheetOffset.absolute(2)));
      expect(const SheetOffset.absolute(1).hashCode, const SheetOffset.absolute(1).hashCode);
      expect(const SheetOffset.proportionalToViewport(0.3), const SheetOffset.proportionalToViewport(0.3));
      expect(
        const SheetOffset.proportionalToViewport(0.3).hashCode,
        const SheetOffset.proportionalToViewport(0.3).hashCode,
      );
      expect(const SheetOffset.proportionalToViewport(0.3), isNot(const SheetOffset.proportionalToViewport(0.4)));
      for (final SheetOffset offset in <SheetOffset>[
        const SheetOffset(1),
        const SheetOffset.absolute(1),
        const SheetOffset.proportionalToViewport(1),
      ]) {
        expect(offset.toString(), isNotEmpty);
      }
    });

    test('layouts compare by value and copy', () {
      final ImmutableViewportLayout copy = ImmutableViewportLayout(
        viewportSize: layout.viewportSize,
        viewportPadding: layout.viewportPadding,
        contentSize: layout.contentSize,
        contentMargin: layout.contentMargin,
        contentBaseline: layout.contentBaseline,
      );
      expect(copy, layout);
      expect(copy.hashCode, layout.hashCode);
      final ImmutableSheetLayout sheet = ImmutableSheetLayout.from(viewportLayout: layout, size: const Size(400, 600));
      expect(sheet.copyWith(), sheet);
      expect(sheet.copyWith(size: const Size(400, 500)).size, const Size(400, 500));
    });
  });

  group('helpers', () {
    test('double utils', () {
      expect(5.0.clampAbs(3), 3);
      expect((-5.0).clampAbs(3), -3);
      expect(4.0.nearest(1, 5), 5);
      expect(2.0.nearest(1, 5), 1);
      expect(5.0.inverseLerp(0, 10), 0.5);
      expect(5.0.inverseLerp(3, 3), 1);
    });

    test('float comparison within a device pixel', () {
      final FloatComp cmp = FloatComp.distance(3);
      expect(cmp.isApprox(1, 1 + 1e-5), isTrue);
      expect(cmp.isOutOfBounds(-1, 0, 1), isTrue);
      expect(cmp.isOutOfBoundsOrApprox(0, 0, 1), isTrue);
      expect(cmp.isInBounds(0.5, 0, 1), isTrue);
      expect(cmp.isInBoundsExclusive(0, 0, 1), isFalse);
      expect(cmp.roundToIfApprox(1 + 1e-6, 1), 1);
      expect(cmp.roundToIfApprox(1.5, 1), 1.5);
    });
  });

  group('theme', () {
    test('equality looks at every value', () {
      const OnaBottomSheetTheme light = OnaBottomSheetTheme.light;
      expect(light, isNot(light.copyWith(touchSlop: 18)));
      expect(light, isNot(light.copyWith(grabberSize: const Size(40, 5))));
      expect(light.hashCode, OnaBottomSheetTheme.light.copyWith().hashCode);
      expect(
        light.copyWith(motion: const OnaSheetMotion(dismissDuration: Duration.zero)).motion.dismissDuration,
        Duration.zero,
      );
      const OnaSheetMotion motion = OnaSheetMotion();
      expect(motion.hashCode, const OnaSheetMotion().hashCode);
      expect(motion, isNot(motion.copyWith(presentDuration: const Duration(seconds: 1))));
      expect(
        motion.copyWith(
          settle: const SpringDescription(mass: 1, stiffness: 1, damping: 1),
          presentCurve: Curves.linear,
        ),
        isNot(motion),
      );
    });
  });

  group('controller', () {
    Widget sheetWith({OnaSheetController? controller, Widget? scope, bool stepless = false}) {
      final Widget sheet = OnaSheetViewport(
        child: RawSheet(
          controller: controller,
          detents: stepless
              ? const SheetDetents.stepless(minOffset: SheetOffset.absolute(200))
              : const SheetDetents(snaps: <SheetOffset>[SheetOffset.absolute(200), SheetOffset(1)]),
          initialOffset: const SheetOffset.absolute(200),
          child: Container(key: const Key('content'), height: 500, color: Colors.white),
        ),
      );
      return MaterialApp(home: scope == null ? sheet : sheet);
    }

    testWidgets('reports where the sheet is and moves it', (tester) async {
      final OnaSheetController controller = autoDispose(OnaSheetController());
      expect(controller.value, isNull, reason: 'nothing attached yet');
      expect(controller.metrics, isNull);
      int heard = 0;
      void listener() => heard++;
      controller.addListener(listener);

      await tester.pumpWidget(sheetWith(controller: controller));
      expect(controller.hasClient, isTrue);
      expect(controller.value, 200);
      expect(controller.metrics!.maxOffset, 500);

      unawaited(controller.animateTo(const SheetOffset(1)));
      await tester.pumpAndSettle();
      expect(controller.value, 500);
      expect(heard, greaterThan(0));
      controller.removeListener(listener);
    });

    testWidgets('a DefaultOnaSheetController shares one controller with the sheets below it', (tester) async {
      late OnaSheetController shared;
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultOnaSheetController(
            child: Builder(
              builder: (BuildContext context) {
                shared = DefaultOnaSheetController.of(context);
                expect(DefaultOnaSheetController.maybeOf(context), same(shared));
                return OnaSheetViewport(
                  child: RawSheet(child: Container(height: 300, color: Colors.white)),
                );
              },
            ),
          ),
        ),
      );
      expect(shared.value, 300, reason: 'the sheet picked up the shared controller');
    });

    testWidgets('of() without a scope says so', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            expect(DefaultOnaSheetController.maybeOf(context), isNull);
            expect(() => DefaultOnaSheetController.of(context), throwsA(isA<AssertionError>()));
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('a position-driven animation runs 0 to 1 between two offsets', (tester) async {
      final OnaSheetController controller = autoDispose(OnaSheetController());
      final SheetOffsetDrivenAnimation animation = SheetOffsetDrivenAnimation(
        controller: controller,
        initialValue: 0.25,
        startOffset: const SheetOffset.absolute(200),
        endOffset: const SheetOffset(1),
      );
      expect(animation.value, 0.25, reason: 'before layout, its initial value');
      expect(animation.status, AnimationStatus.forward);
      int heard = 0;
      void listener() => heard++;
      animation
        ..addListener(listener)
        ..addStatusListener((_) {})
        ..removeStatusListener((_) {});

      await tester.pumpWidget(sheetWith(controller: controller, stepless: true));
      expect(animation.value, 0);
      unawaited(controller.animateTo(const SheetOffset.absolute(350)));
      await tester.pumpAndSettle();
      expect(animation.value, closeTo(0.5, 1e-6));
      unawaited(controller.animateTo(const SheetOffset(1)));
      await tester.pumpAndSettle();
      expect(animation.value, 1);
      expect(heard, greaterThan(0));
      animation.removeListener(listener);
    });
  });

  group('drags and notifications', () {
    testWidgets('a drag is reported as it starts and moves, and every notification describes the sheet', (
      tester,
    ) async {
      final List<SheetNotification> heard = <SheetNotification>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationListener<SheetNotification>(
            onNotification: (SheetNotification n) {
              heard.add(n);
              return false;
            },
            child: OnaSheetViewport(
              child: RawSheet(
                detents: const SheetDetents(snaps: <SheetOffset>[SheetOffset.absolute(200), SheetOffset(1)]),
                initialOffset: const SheetOffset.absolute(200),
                child: Container(key: const Key('content'), height: 500, color: Colors.white),
              ),
            ),
          ),
        ),
      );
      // Near the content's top: at its lower stop most of it is below the 600 pt test screen.
      final TestGesture finger = await tester.startGesture(
        tester.getTopLeft(find.byKey(const Key('content'))) + const Offset(100, 20),
      );
      await finger.moveBy(const Offset(0, -40));
      await tester.pump();
      await finger.cancel();
      await tester.pumpAndSettle();

      expect(heard.whereType<SheetDragStartNotification>(), isNotEmpty);
      expect(heard.whereType<SheetDragUpdateNotification>(), isNotEmpty);
      expect(heard.whereType<SheetUpdateNotification>(), isNotEmpty);
      for (final SheetNotification n in heard) {
        expect(n.toString(), contains('offset'));
      }
      final SheetDragStartNotification start = heard.whereType<SheetDragStartNotification>().first;
      expect(start.dragDetails.copyWith().axisDirection, start.dragDetails.axisDirection);
      final SheetDragUpdateNotification update = heard.whereType<SheetDragUpdateNotification>().first;
      expect(update.dragDetails.copyWith(deltaY: 3).deltaY, 3);
    });

    testWidgets('a drag past the top is reported as overflow, and a release as an end', (tester) async {
      final List<SheetNotification> heard = <SheetNotification>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationListener<SheetNotification>(
            onNotification: (SheetNotification n) {
              heard.add(n);
              return false;
            },
            child: OnaSheetViewport(
              child: RawSheet(
                physics: const ClampingSheetPhysics(),
                child: Container(key: const Key('content'), height: 500, color: Colors.white),
              ),
            ),
          ),
        ),
      );
      await tester.dragFrom(
        tester.getTopLeft(find.byKey(const Key('content'))) + const Offset(100, 20),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      final SheetOverflowNotification overflow = heard.whereType<SheetOverflowNotification>().first;
      expect(overflow.overflow, isNonZero);
      expect(overflow.toString(), contains('overflow'));
      final SheetDragEndNotification end = heard.whereType<SheetDragEndNotification>().first;
      expect(end.dragDetails.copyWith(velocityX: 1).velocityX, 1);
      expect(end.toString(), contains('offset'));
    });
  });

  group('configuration values', () {
    test('scroll and drag configurations compare by value', () {
      const SheetScrollConfiguration on = SheetScrollConfiguration();
      expect(on, const SheetScrollConfiguration());
      expect(on.hashCode, const SheetScrollConfiguration().hashCode);
      expect(on, isNot(const SheetScrollConfiguration(scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop)));
      expect(SheetScrollConfiguration.disabled, same(SheetScrollConfiguration.disabled));
      expect(SheetScrollConfiguration.disabled.scrollSyncMode, SheetScrollHandlingBehavior.always);
      expect(SheetScrollConfiguration.disabled.delegateUnhandledOverscrollToChild, isFalse);
      expect(SheetScrollConfiguration.disabled.hashCode, SheetScrollConfiguration.disabled.hashCode);

      const SheetDragConfiguration drag = SheetDragConfiguration();
      expect(drag, const SheetDragConfiguration());
      expect(drag.hashCode, const SheetDragConfiguration().hashCode);
      expect(drag.dragStartBehavior, DragStartBehavior.down);
      expect(drag, isNot(const SheetDragConfiguration(dragStartBehavior: DragStartBehavior.start)));
      expect(SheetDragConfiguration.disabled.hitTestBehavior, isNull);
      expect(SheetDragConfiguration.disabled.deviceKinds, isNull);
      expect(SheetDragConfiguration.disabled.dragStartBehavior, DragStartBehavior.down);
    });

    test('metrics compare by value and copy', () {
      const ImmutableSheetMetrics metrics = ImmutableSheetMetrics(
        offset: 300,
        minOffset: 200,
        maxOffset: 600,
        size: Size(400, 600),
        contentSize: Size(400, 600),
        viewportSize: Size(400, 1000),
        viewportPadding: EdgeInsets.zero,
        contentBaseline: 0,
        contentMargin: EdgeInsets.zero,
        devicePixelRatio: 3,
      );
      expect(metrics.copyWith(), metrics);
      expect(metrics.copyWith().hashCode, metrics.hashCode);
      expect(metrics.copyWith(offset: 350), isNot(metrics));
      expect(metrics.copyWith(offset: 350).offset, 350);
      expect(metrics.rect, const Rect.fromLTWH(0, 700, 400, 600));
      expect(metrics.visibleRect, const Rect.fromLTWH(0, 700, 400, 300));
      expect(metrics.contentRect, const Rect.fromLTWH(0, 700, 400, 600));
    });
  });

  group('rebuilt with new settings', () {
    testWidgets('a scaffold and a viewport take new settings without rebuilding the sheet', (tester) async {
      Widget build({required bool extend, required double top}) => MaterialApp(
        home: OnaSheetViewport(
          padding: EdgeInsets.only(top: top),
          child: OnaBottomSheet(
            child: OnaSheetScaffold(
              extendBodyBehindHeader: extend,
              extendBodyBehindFooter: extend,
              footerVisibility: FooterVisibility.natural(ignoreBottomInset: extend),
              header: const SizedBox(height: 40, child: Text('header')),
              footer: const SizedBox(height: 40, child: Text('footer')),
              body: const SizedBox(height: 200, child: Text('body')),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(extend: false, top: 0));
      final double bodyTop = tester.getTopLeft(find.text('body')).dy;
      await tester.pumpWidget(build(extend: true, top: 30));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('body')).dy, isNot(bodyTop), reason: 'the body now runs under the header');
    });

    testWidgets('a scaffold refuses to report intrinsic sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnaSheetViewport(
            child: OnaBottomSheet(
              child: OnaSheetScaffold(body: Container(height: 100, color: Colors.white)),
            ),
          ),
        ),
      );
      final RenderBox layout = tester.renderObject(
        find.descendant(
          of: find.byType(OnaSheetScaffold),
          matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ScaffoldLayout'),
        ),
      );
      expect(() => layout.getMinIntrinsicHeight(100), throwsFlutterError);
      expect(() => layout.getMaxIntrinsicWidth(100), throwsFlutterError);
    });
  });
}
