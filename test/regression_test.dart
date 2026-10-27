import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ona_bottom_sheet/src/foundation/activity.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart';
import 'package:ona_bottom_sheet/src/foundation/model_owner.dart';
import 'package:ona_bottom_sheet/src/physics/detents.dart';
import 'package:ona_bottom_sheet/src/physics/physics.dart';
import 'package:ona_bottom_sheet/src/widgets/bottom_sheet.dart';
import 'package:ona_bottom_sheet/src/widgets/decorations.dart';
import 'package:ona_bottom_sheet/src/widgets/viewport.dart';

import 'src/flutter_test_x.dart';
import 'src/keyboard_inset_simulation.dart';
import 'src/matchers.dart';

void main() {
  // Clamped physics must never bounce.
  testWidgets('Unexpected bouncing animation with ClampingSheetPhysics', (tester) async {
    final viewportKey = GlobalKey<OnaSheetViewportState>();
    await tester.pumpWidget(
      MaterialApp(
        home: OnaSheetViewport(
          key: viewportKey,
          child: OnaBottomSheet(
            initialOffset: const SheetOffset.absolute(300),
            detents: const SheetDetents(snaps: [SheetOffset.absolute(300), SheetOffset(1)]),
            physics: const ClampingSheetPhysics(),
            child: Container(color: Colors.white, height: 400),
          ),
        ),
      ),
    );

    final offsetHistory = <double>[];
    viewportKey.currentState!.model.addListener(() {
      offsetHistory.add(viewportKey.currentState!.model.offset);
    });

    expect(tester.getRect(find.byType(OnaBottomSheet)).top, 300);
    await tester.fling(find.byType(OnaBottomSheet), const Offset(0, -80), 2000);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(OnaBottomSheet)).top, 200);
    expect(
      offsetHistory,
      isMonotonicallyIncreasing,
      reason: 'The sheet should never bounce back with ClampingSheetPhysics',
    );
  });

  // An over-dragged, stretched sheet animates back without switching activities midway.
  testWidgets('Stretch sheet should not switch from ballistic to settling '
      'when animating back from over-drag', (tester) async {
    late SheetModel model;
    await tester.pumpWidget(
      MaterialApp(
        home: OnaSheetViewport(
          child: OnaBottomSheet(
            key: const Key('sheet'),
            physics: const BouncingSheetPhysics(),
            decoration: const MaterialSheetDecoration(size: SheetSize.stretch),
            child: Builder(
              builder: (context) {
                model = SheetModelOwner.of(context)!;
                return const SizedBox(height: 500);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(model.activity, isA<IdleSheetActivity>());
    expect(tester.getRect(find.byId('sheet')).top, 100);

    // Over-drag the sheet upward.
    final gesture = await tester.startDrag(tester.getCenter(find.byType(OnaBottomSheet)), AxisDirection.up);
    await gesture.moveUpwardBy(100);
    await tester.pump();
    expect(model.activity, isA<DragSheetActivity>());
    expect(tester.getRect(find.byId('sheet')).top, lessThan(100), reason: 'The sheet should be over-dragged');

    // Release the drag to start ballistic animation.
    await gesture.up();
    await tester.pump();
    expect(model.activity, isA<BallisticSheetActivity>());

    // After one animation frame, the activity should still be ballistic
    // (not settling). With the bug, the stretch sheet's size changes on
    // each offset update, causing applyNewLayout() to replace the
    // ballistic activity with a settling activity.
    await tester.pump(const Duration(milliseconds: 17));
    expect(model.activity, isA<BallisticSheetActivity>());
    expect(tester.getRect(find.byId('sheet')).top, lessThan(100));

    await tester.pumpAndSettle();
    expect(model.activity, isA<IdleSheetActivity>());
    expect(tester.getRect(find.byId('sheet')).top, 100, reason: 'The sheet should settle back to the initial position');
  });

  // Stepless detents keep what is visible when the keyboard comes up.
  testWidgets('SteplessSheetDetents should maintain visible extent when keyboard appears', (tester) async {
    const keyboardHeight = 200.0;
    final sheetKey = GlobalKey();
    final keyboardSimulationKey = GlobalKey<KeyboardInsetSimulationState>();

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardInsetSimulation(
          key: keyboardSimulationKey,
          keyboardHeight: keyboardHeight,
          child: Builder(
            builder: (context) {
              return OnaSheetViewport(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: OnaBottomSheet(
                  key: sheetKey,
                  initialOffset: const SheetOffset.absolute(150),
                  detents: const SheetDetents.stepless(),
                  child: const SizedBox(height: 300, width: double.infinity),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(sheetKey)),
      const Rect.fromLTWH(0, 450, 800, 300),
      reason: 'The sheet should be at the initial offset',
    );

    unawaited(keyboardSimulationKey.currentState!.showKeyboard(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(sheetKey)),
      const Rect.fromLTWH(0, 250, 800, 300),
      reason:
          'The sheet should move up by the keyboard height '
          'while maintaining the visible extent',
    );

    unawaited(keyboardSimulationKey.currentState!.hideKeyboard(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(sheetKey)),
      const Rect.fromLTWH(0, 450, 800, 300),
      reason: 'The sheet should move back down to the initial offset',
    );
  });

  // A sheet disposed before its first layout must not crash.
  testWidgets('Disposing the sheet before its first layout should not crash', (tester) async {
    // Build the sheet but stop before the layout phase so its model is
    // attached to the viewport without having any metrics yet.
    await tester.pumpWidget(
      const MaterialApp(
        home: OnaSheetViewport(child: OnaBottomSheet(child: SizedBox(height: 400))),
      ),
      phase: EnginePhase.build,
    );

    // Tearing the sheet down now detaches a model that never had metrics.
    // Reading the outgoing model's offset/rect in that state used to throw
    // a "Null check operator used on a null value" error.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // Rebuilding the sheet subtree with a new key reuses the enclosing
  // OnaSheetViewport, so the new sheet's owner attaches its model in the build
  // phase while the old owner is only unmounted in the finalization phase,
  // after the layout pass. SheetModelOwnerState.dispose() used to detach
  // whatever model was attached at that point, including the model it
  // never owned, leaving the viewport with no model at all.
  group('Swapping the sheet within the same viewport', () {
    final viewportKey = GlobalKey<OnaSheetViewportState>();

    Widget buildApp(String sheetKey, {double contentHeight = 400}) {
      return MaterialApp(
        home: OnaSheetViewport(
          key: viewportKey,
          child: OnaBottomSheet(
            key: ValueKey(sheetKey),
            child: SizedBox(height: contentHeight),
          ),
        ),
      );
    }

    testWidgets("should keep the new sheet's model attached", (tester) async {
      await tester.pumpWidget(buildApp('old'));
      await tester.pumpWidget(buildApp('new'));

      expect(
        viewportKey.currentState!.model.hasMetrics,
        isTrue,
        reason:
            'Disposing the old owner should not detach the model that the '
            'new owner attached to the same viewport',
      );
    });

    testWidgets('should not crash when laid out on a later frame', (tester) async {
      await tester.pumpWidget(buildApp('old'));
      await tester.pumpWidget(buildApp('new'));

      // The detached model is never reattached, so the next layout pass of the
      // surviving sheet used to hit 'assert(_model._inner != null)' in
      // _RenderSheetSkelton.performLayout, and a null check error on the
      // subsequent _model._inner! dereference in release builds.
      await tester.pumpWidget(buildApp('new', contentHeight: 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
