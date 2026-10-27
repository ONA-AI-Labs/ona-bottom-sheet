import 'package:flutter/rendering.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart';
import 'package:ona_bottom_sheet/src/physics/detents.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';

void main() {
  const testLayout = ImmutableViewportLayout(
    viewportSize: testScreenSize,
    viewportPadding: EdgeInsets.zero,
    contentSize: Size(800, 500),
    contentMargin: EdgeInsets.zero,
    contentBaseline: 0,
  );

  group('SingleSheetDetents', () {
    test('getSnapOffset: the offset does not affect the result', () {
      var result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: the velocity does not affect the result', () {
      var result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 600, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getSnapOffset(testLayout, 500, -100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getBoundaries: min and max offsets are always the same', () {
      var result = const SingleSheetDetents(snap: SheetOffset.absolute(500)).getBoundaries(testLayout);
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));

      result = const SingleSheetDetents(
        snap: SheetOffset.absolute(500),
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));

      result = const SingleSheetDetents(
        snap: SheetOffset.absolute(500),
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 500)));
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));
    });
  });

  group('SteplessSheetDetents', () {
    const snap = SteplessSheetDetents(minOffset: SheetOffset(0), maxOffset: SheetOffset(1));

    test('getSnapOffset: returns minOffset when '
        'the current offset is less than minOffset', () {
      final result = snap.getSnapOffset(testLayout, -100, 0);
      expect(result, const SheetOffset(0));
    });

    test('getSnapOffset: returns maxOffset '
        'when metrics.offset is greater than maxOffset', () {
      final result = snap.getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset(1));
    });

    test('getSnapOffset: returns minOffset when offset is at minOffset', () {
      final result = snap.getSnapOffset(testLayout, 0, 0);
      expect(result, const SheetOffset(0));
    });

    test('getSnapOffset: returns maxOffset when offset is at maxOffset', () {
      final result = snap.getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset(1));
    });

    test('getSnapOffset: returns an absolute offset relative to baseline '
        'when the current offset is within bounds', () {
      final result = snap.getSnapOffset(testLayout, 250, 0);
      expect(result.resolve(testLayout), 250);
      expect(result, isA<AbsoluteSheetOffset>().having((it) => it.relativeToBaseline, 'relativeToBaseline', true));
    });

    test('getSnapOffset: returned offset adapts to layout changes', () {
      final result = snap.getSnapOffset(testLayout, 250, 0);
      // With keyboard (baseline increases by 200), the resolved offset should
      // shift up to maintain the same visible extent: 250 + 200 = 450
      final layoutWithKeyboard = testLayout.copyWith(contentBaseline: 200);
      expect(result.resolve(layoutWithKeyboard), 450);
    });

    test('getBoundaries: always returns min and max offsets', () {
      var result = snap.getBoundaries(testLayout);
      expect(result, (const SheetOffset(0), const SheetOffset(1)));

      result = snap.getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset(0), const SheetOffset(1)));

      result = snap.getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset(0), const SheetOffset(1)));
      result = snap.getBoundaries(testLayout.copyWith(contentSize: const Size(800, 300)));
      expect(result, (const SheetOffset(0), const SheetOffset(1)));
    });
  });
  group('MultiSheetDetents with single snap offset', () {
    test('getSnapOffset', () {
      var result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 400, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 600, -100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 500, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: [SheetOffset.absolute(500)]).getSnapOffset(testLayout, 500, -100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getBoundaries', () {
      var result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(500)],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(500)],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(500)],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 500)));
      expect(result, (const SheetOffset.absolute(500), const SheetOffset.absolute(500)));
    });
  });

  group('MultiSheetDetents with two snap offsets', () {
    const snaps = [SheetOffset.absolute(0), SheetOffset.absolute(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, -100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(500), SheetOffset.absolute(0)],
      ).getSnapOffset(testLayout, 100, 0);
      expect(result, const SheetOffset.absolute(0));
    });

    test('getBoundaries', () {
      var result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 500)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(500), SheetOffset.absolute(0)],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));
    });
  });
  group('MultiSheetDetents with three snap offsets', () {
    const snaps = [SheetOffset.absolute(0), SheetOffset.absolute(250), SheetOffset.absolute(500)];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, -100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, -100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, -100);
      expect(result, const SheetOffset.absolute(500));
    });

    test('getSnapOffset: the order of "snaps" list does not matter', () {
      final result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(250), SheetOffset.absolute(500), SheetOffset.absolute(0)],
      ).getSnapOffset(testLayout, 200, 0);
      expect(result, const SheetOffset.absolute(250));
    });

    test('getBoundaries', () {
      var result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 500)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSheetDetents(
        snaps: [SheetOffset.absolute(250), SheetOffset.absolute(500), SheetOffset.absolute(0)],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(500)));
    });
  });

  group('MultiSheetDetents with four snap offsets', () {
    const snaps = [
      SheetOffset.absolute(0),
      SheetOffset.absolute(250),
      SheetOffset.absolute(500),
      SheetOffset.absolute(750),
    ];

    test('getSnapOffset: |velocity| < kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 0);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, 0);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 0);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 700, 0);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 750, 0);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 800, 0);
      expect(result, const SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity > kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, 100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, 100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, 100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, 100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, 100);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, 100);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, 100);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 700, 100);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 750, 100);
      expect(result, const SheetOffset.absolute(750));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 800, 100);
      expect(result, const SheetOffset.absolute(750));
    });

    test('getSnapOffset: velocity < -kMinFlingVelocity', () {
      var result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, -100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 0, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 100, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 200, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 250, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 300, -100);
      expect(result, const SheetOffset.absolute(0));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 400, -100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 500, -100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 600, -100);
      expect(result, const SheetOffset.absolute(250));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 700, -100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 750, -100);
      expect(result, const SheetOffset.absolute(500));

      result = const MultiSheetDetents(snaps: snaps).getSnapOffset(testLayout, 800, -100);
      expect(result, const SheetOffset.absolute(750));
    });

    test('getBoundaries', () {
      var result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(750)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 600)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(750)));

      result = const MultiSheetDetents(
        snaps: snaps,
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 500)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(750)));
    });

    test('getBoundaries: the order of "snaps" list does not matter', () {
      final result = const MultiSheetDetents(
        snaps: [
          SheetOffset.absolute(750),
          SheetOffset.absolute(500),
          SheetOffset.absolute(250),
          SheetOffset.absolute(0),
        ],
      ).getBoundaries(testLayout.copyWith(contentSize: const Size(800, 400)));
      expect(result, (const SheetOffset.absolute(0), const SheetOffset.absolute(750)));
    });
  });
}
