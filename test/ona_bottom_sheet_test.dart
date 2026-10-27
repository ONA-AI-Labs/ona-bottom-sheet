import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart' show ImmutableViewportLayout;

/// Ona's sheet, as people use it: shown with [showOnaBottomSheet], dressed by [OnaBottomSheetTheme].
void main() {
  const Size phone = Size(390, 844);

  /// Puts a phone-sized app on screen and opens the sheet [open] shows; returns where the page's button stood.
  Future<Rect> host(
    WidgetTester tester,
    void Function(BuildContext context) open, {
    ThemeData? theme,
    double safeTop = 0,
    bool disableAnimations = false,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3
      ..padding = FakeViewPadding(top: safeTop * 3);
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: disableAnimations,
    );
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (BuildContext context, Widget? child) => Directionality(textDirection: direction, child: child!),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => open(context), child: const Text('open')),
            ),
          ),
        ),
      ),
    );
    final Rect page = tester.getRect(find.text('open'));
    await tester.tap(find.text('open'));
    await settle(tester);
    return page;
  }

  double top(WidgetTester tester) => tester.getRect(find.byType(OnaSheetScaffold).last).top;

  Widget header() => const Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(height: 7),
      OnaSheetGrabber(),
      SizedBox(height: 44, child: Center(child: Text('Title'))),
    ],
  );

  Widget long({Widget? footer, bool keyboardField = false}) => OnaBottomSheet(
    child: OnaSheetScaffold(
      header: header(),
      footer: footer,
      footerVisibility: const FooterVisibility.always(ignoreBottomInset: true, scrimColor: Colors.white),
      body: ListView(
        dragStartBehavior: DragStartBehavior.down,
        children: <Widget>[
          if (keyboardField) const TextField(),
          for (int i = 0; i < 40; i++) SizedBox(height: 50, child: Text('Row $i')),
        ],
      ),
    ),
  );

  Widget short() => OnaBottomSheet(
    child: OnaSheetScaffold(
      header: header(),
      body: const Padding(padding: EdgeInsets.all(24), child: Text('Delete this conversation?')),
    ),
  );

  void showLong(BuildContext context, {Widget? footer, bool keyboardField = false}) => unawaited(
    showOnaBottomSheet<void>(
      context: context,
      builder: (_) => long(footer: footer, keyboardField: keyboardField),
    ),
  );

  group('stops', () {
    testWidgets('a long sheet opens at half, pulls to full through its list, drops to half, then closes', (
      tester,
    ) async {
      final Rect page = await host(tester, showLong);
      expect(top(tester), moreOrLessEquals(phone.height / 2, epsilon: 1));

      await tester.drag(find.text('Row 2'), const Offset(0, -500));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(0, epsilon: 1));
      expect(find.text('Row 2').hitTestable(), findsOneWidget, reason: 'the sheet grew before the list scrolled');
      expect(tester.getRect(find.text('open')), page, reason: 'the page behind never moves');

      await tester.drag(find.text('Title'), const Offset(0, 250));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(phone.height / 2, epsilon: 1));

      await tester.drag(find.text('Title'), const Offset(0, 400));
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsNothing);
    });

    testWidgets('content that fits rests whole, alone', (tester) async {
      await host(tester, (BuildContext context) {
        unawaited(showOnaBottomSheet<void>(context: context, builder: (_) => short()));
      });
      final double rest = top(tester);
      expect(rest, greaterThan(phone.height / 2));

      await tester.drag(find.text('Title'), const Offset(0, -300));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(rest, epsilon: 0.5), reason: 'clamped: there is no higher stop');
    });

    testWidgets('a slow, short pull settles back; a flick carries the sheet to the next stop', (tester) async {
      await host(tester, showLong);
      final double half = top(tester);

      await tester.timedDrag(find.text('Title'), const Offset(0, -60), const Duration(milliseconds: 600));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(half, epsilon: 1));

      await tester.fling(find.text('Title'), const Offset(0, -80), 1500);
      await settle(tester);
      expect(top(tester), moreOrLessEquals(0, epsilon: 1));
    });

    testWidgets('at full it stops at the safe area, and a pull further up moves it not at all', (tester) async {
      await host(tester, showLong, safeTop: 59);
      await tester.drag(find.text('Title'), const Offset(0, -600));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(59, epsilon: 0.5));

      final TestGesture finger = await tester.startGesture(tester.getCenter(find.text('Title')));
      await finger.moveBy(const Offset(0, -40));
      await finger.moveBy(const Offset(0, -160));
      await tester.pump();
      expect(top(tester), moreOrLessEquals(59, epsilon: 0.5));
      await finger.up();
      await settle(tester);
    });
  });

  group('the finger', () {
    for (final String where in <String>['Title', 'Row 2']) {
      testWidgets('from "$where", the sheet follows the finger exactly, slop included', (tester) async {
        await host(tester, showLong);
        final double half = top(tester);

        final TestGesture finger = await tester.startGesture(tester.getCenter(find.text(where)));
        await finger.moveBy(const Offset(0, 12));
        await finger.moveBy(const Offset(0, 30));
        await tester.pump();
        expect(top(tester), moreOrLessEquals(half + 42, epsilon: 0.5), reason: 'no slop left behind the finger');
        await finger.up();
        await settle(tester);
      });
    }

    testWidgets('where the list competes for the drag, it starts after 10 pt, not 18', (tester) async {
      await host(tester, showLong);
      final double half = top(tester);
      final TestGesture finger = await tester.startGesture(tester.getCenter(find.text('Row 2')));
      await finger.moveBy(const Offset(0, 9));
      await tester.pump();
      expect(top(tester), half, reason: 'within the slop nothing moves');
      await finger.moveBy(const Offset(0, 2));
      await tester.pump();
      expect(top(tester), moreOrLessEquals(half + 11, epsilon: 0.5), reason: 'past 10 pt it is already moving');
      await finger.up();
      await settle(tester);
    });
  });

  group('closing', () {
    testWidgets('a hard flick closes the sheet at its own speed, quicker than an ordinary close', (tester) async {
      await host(tester, showLong);
      // 120 pt at 4000 pt/s leaves 86% of the screen: about 180 ms at the finger's speed, 257 ms the ordinary way.
      await tester.fling(find.text('Title'), const Offset(0, 120), 4000);
      for (int i = 0; i < 13; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(OnaBottomSheet), findsNothing);
    });

    testWidgets('a sheet that may not be dismissed drags, and springs back', (tester) async {
      await host(tester, (BuildContext context) {
        unawaited(showOnaBottomSheet<void>(context: context, isDismissible: false, builder: (_) => short()));
      });
      final double rest = top(tester);
      await tester.drag(find.text('Title'), const Offset(0, 400));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(rest, epsilon: 0.5));
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsOneWidget, reason: 'nor does a tap outside close it');
    });

    testWidgets('a PopScope that refuses keeps the sheet up through a swipe', (tester) async {
      await host(tester, (BuildContext context) {
        unawaited(
          showOnaBottomSheet<void>(
            context: context,
            builder: (_) => PopScope(canPop: false, child: short()),
          ),
        );
      });
      await tester.drag(find.text('Title'), const Offset(0, 500));
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsOneWidget);
    });

    testWidgets('with animations removed it appears and goes at once', (tester) async {
      await host(tester, (BuildContext context) {
        unawaited(showOnaBottomSheet<void>(context: context, builder: (_) => short()));
      }, disableAnimations: true);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump();
      expect(find.byType(OnaBottomSheet), findsNothing);
    });
  });

  group('footer and keyboard', () {
    testWidgets('at half, the pinned footer is on screen and stands on the sheet colour', (tester) async {
      await host(
        tester,
        (BuildContext context) => showLong(context, footer: const SizedBox(height: 80, child: Text('Done'))),
      );
      expect(top(tester), moreOrLessEquals(phone.height / 2, epsilon: 1));
      expect(find.text('Done').hitTestable(), findsOneWidget);
      expect(tester.getRect(find.text('Done')).bottom, lessThanOrEqualTo(phone.height));
      final RenderObject scrim = tester.renderObject(
        find.ancestor(
          of: find.text('Done'),
          matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_FooterScrim'),
        ),
      );
      expect(scrim, paints..rect(), reason: 'rows run on below it, so the fade is drawn');
    });

    testWidgets('with the keyboard up, the sheet rests at full alone and its field stays above the keyboard', (
      tester,
    ) async {
      await host(tester, (BuildContext context) => showLong(context, keyboardField: true));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await settle(tester);
      expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(phone.height - 300));
      final double rest = top(tester);
      await tester.timedDrag(find.text('Title'), const Offset(0, 60), const Duration(milliseconds: 600));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(rest, epsilon: 1), reason: 'one stop while typing');
      tester.view.resetViewInsets();
    });
  });

  group('theme', () {
    Color surface(WidgetTester tester) {
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(OnaSheetScaffold), matching: find.byType(DecoratedBox)).last,
      );
      return (box.decoration as ShapeDecoration).color!;
    }

    testWidgets('light by default, dark in a dark theme, and an extension wins over both', (tester) async {
      await host(tester, showLong);
      expect(surface(tester), OnaBottomSheetTheme.light.backgroundColor);
    });

    testWidgets('dark', (tester) async {
      await host(tester, showLong, theme: ThemeData(brightness: Brightness.dark));
      expect(surface(tester), OnaBottomSheetTheme.dark.backgroundColor);
    });

    testWidgets('extension', (tester) async {
      await host(
        tester,
        showLong,
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            OnaBottomSheetTheme.light.copyWith(backgroundColor: const Color(0xFFFFF8E7)),
          ],
        ),
      );
      expect(surface(tester), const Color(0xFFFFF8E7));
    });

    test('copyWith, lerp and equality', () {
      const OnaBottomSheetTheme a = OnaBottomSheetTheme.light;
      expect(a.copyWith(), a);
      expect(a.copyWith(cornerRadius: 20).cornerRadius, 20);
      expect(a.lerp(OnaBottomSheetTheme.dark, 0).backgroundColor, a.backgroundColor);
      expect(a.lerp(OnaBottomSheetTheme.dark, 1).backgroundColor, OnaBottomSheetTheme.dark.backgroundColor);
      expect(a.lerp(null, 0.5), a);
      expect(const OnaSheetMotion(), const OnaSheetMotion());
      expect(const OnaSheetMotion().copyWith(flickProjection: 0).flickProjection, 0);
    });
  });

  group('accessibility', () {
    testWidgets('the grabber is adjustable: increase moves the sheet up a stop, decrease down', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await host(tester, showLong);
      final SemanticsNode grabber = tester.getSemantics(find.byType(OnaSheetGrabber));
      grabber.owner!.performAction(grabber.id, SemanticsAction.increase);
      await settle(tester);
      expect(top(tester), moreOrLessEquals(0, epsilon: 1));
      final SemanticsNode again = tester.getSemantics(find.byType(OnaSheetGrabber));
      again.owner!.performAction(again.id, SemanticsAction.decrease);
      await settle(tester);
      expect(top(tester), moreOrLessEquals(phone.height / 2, epsilon: 1));
      semantics.dispose();
    });

    testWidgets("a screen reader's escape closes a dismissible sheet", (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await host(tester, (BuildContext context) {
        unawaited(showOnaBottomSheet<void>(context: context, builder: (_) => short()));
      });
      final SemanticsNode node = tester.getSemantics(
        find.ancestor(of: find.byType(OnaSheetViewport), matching: find.byType(Semantics)).first,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.dismiss);
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsNothing);
      semantics.dispose();
    });

    testWidgets('right to left lays out and drags the same', (tester) async {
      await host(tester, showLong, direction: TextDirection.rtl);
      expect(top(tester), moreOrLessEquals(phone.height / 2, epsilon: 1));
      await tester.drag(find.text('Title'), const Offset(0, -500));
      await settle(tester);
      expect(top(tester), moreOrLessEquals(0, epsilon: 1));
    });
  });

  group('always-on sheet', () {
    testWidgets('rests on a screen without a route, moves between its stops, and leaves the page usable', (
      tester,
    ) async {
      tester.view
        ..physicalSize = phone * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: TextButton(onPressed: () => taps++, child: const Text('map')),
                ),
                OnaSheetViewport(
                  child: OnaBottomSheet(
                    detents: const SheetDetents(
                      snaps: <SheetOffset>[SheetOffset.absolute(120), SheetOffset(1)],
                      flickProjection: 0.499,
                    ),
                    initialOffset: const SheetOffset.absolute(120),
                    child: OnaSheetScaffold(
                      header: header(),
                      body: ListView(
                        children: <Widget>[for (int i = 0; i < 40; i++) SizedBox(height: 50, child: Text('Place $i'))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await settle(tester);
      expect(top(tester), moreOrLessEquals(phone.height - 120, epsilon: 1));
      await tester.tap(find.text('map'));
      expect(taps, 1, reason: 'the page above the sheet stays interactive');

      await tester.fling(find.text('Title'), const Offset(0, -100), 2000);
      await settle(tester);
      expect(top(tester), moreOrLessEquals(0, epsilon: 1));
    });
  });

  group('detents', () {
    const ImmutableViewportLayout layout = ImmutableViewportLayout(
      viewportSize: Size(400, 1000),
      viewportPadding: EdgeInsets.zero,
      contentSize: Size(400, 1000),
      contentMargin: EdgeInsets.zero,
      contentBaseline: 0,
    );

    test('more than three stops in any order: the nearest and its neighbours are found in order', () {
      const SheetDetents detents = SheetDetents(
        snaps: <SheetOffset>[
          SheetOffset.absolute(900),
          SheetOffset.absolute(100),
          SheetOffset.absolute(500),
          SheetOffset.absolute(300),
        ],
      );
      expect(detents.getSnapOffset(layout, 320, 0).resolve(layout), 300);
      expect(detents.getSnapOffset(layout, 320, 1000).resolve(layout), 500);
      expect(detents.getSnapOffset(layout, 320, -1000).resolve(layout), 100);
    });

    test('with a flick projection, a slow release stays and a fast one moves on, but never past the next stop', () {
      const SheetDetents detents = SheetDetents(
        snaps: <SheetOffset>[SheetOffset.absolute(100), SheetOffset.absolute(500), SheetOffset.absolute(900)],
        flickProjection: 0.5,
      );
      expect(detents.getSnapOffset(layout, 520, 200).resolve(layout), 500, reason: 'projects to 620: nearer 500');
      expect(detents.getSnapOffset(layout, 520, 800).resolve(layout), 900, reason: 'projects to 920');
      expect(detents.getSnapOffset(layout, 520, -5000).resolve(layout), 100, reason: 'far, but one stop at most');
      expect(detents.getSnapOffset(layout, 120, 5000).resolve(layout), 500, reason: 'one stop at most');
    });

    test('adaptive: content that fits has one stop; longer content half and full; the keyboard leaves one', () {
      const AdaptiveSheetDetents adaptive = AdaptiveSheetDetents();
      ViewportLayout withContent(double height, {double keyboard = 0}) => ImmutableViewportLayout(
        viewportSize: const Size(400, 1000),
        viewportPadding: EdgeInsets.zero,
        contentSize: Size(400, height),
        contentMargin: EdgeInsets.only(bottom: keyboard),
        contentBaseline: keyboard,
      );
      expect(adaptive.rest.resolve(withContent(600)), 600);
      expect(adaptive.rest.resolve(withContent(1000)), 500);
      expect(adaptive.rest.resolve(withContent(700, keyboard: 300)), 1000);
      expect(adaptive, const AdaptiveSheetDetents());
    });
  });
}

/// Lets springs and transitions finish without pumpAndSettle (a focused field's caret never settles).
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
