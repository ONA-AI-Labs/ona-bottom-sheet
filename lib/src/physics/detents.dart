import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';

import '../foundation/model.dart';

/// The stops a sheet can rest at, and how it picks one when a drag ends.
///
/// A sheet moves freely between its lowest and highest stop ([getBoundaries]); when the finger lifts, it settles
/// on the stop [getSnapOffset] picks.
abstract interface class SheetDetents {
  /// Rests at any of [snaps]; see [MultiSheetDetents].
  const factory SheetDetents({required List<SheetOffset> snaps, double minFlingSpeed, double? flickProjection}) =
      MultiSheetDetents;

  /// Rests at [snap] alone.
  const factory SheetDetents.single({required SheetOffset snap}) = SingleSheetDetents;

  /// Rests wherever it is let go, between [minOffset] and [maxOffset].
  const factory SheetDetents.stepless({SheetOffset minOffset, SheetOffset maxOffset}) = SteplessSheetDetents;

  /// Ona's stops: whole content when it fits, else half and full; see [AdaptiveSheetDetents].
  const factory SheetDetents.adaptive({double half, double flickProjection}) = AdaptiveSheetDetents;

  /// Returns an position to which a sheet should eventually settle
  /// based on the current [layout], [offset] and [velocity] of the sheet.
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity);

  /// Returns the minimum and maximum offsets.
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout);
}

/// A single stop.
class SingleSheetDetents implements SheetDetents {
  /// Creates detents with the one stop [snap].
  const SingleSheetDetents({required this.snap});

  /// The stop.
  final SheetOffset snap;

  @override
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity) {
    return snap;
  }

  @override
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout) {
    return (snap, snap);
  }
}

/// No fixed stops: the sheet rests wherever it is let go, within a range.
class SteplessSheetDetents implements SheetDetents {
  /// Creates stepless detents between [minOffset] and [maxOffset].
  const SteplessSheetDetents({this.minOffset = const SheetOffset(0), this.maxOffset = const SheetOffset(1)});

  /// The lowest the sheet rests.
  final SheetOffset minOffset;

  /// The highest the sheet rests.
  final SheetOffset maxOffset;

  @override
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout) {
    return (minOffset, maxOffset);
  }

  @override
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity) {
    final minimum = minOffset.resolve(layout);
    final maximum = maxOffset.resolve(layout);
    if (offset <= minimum) {
      return minOffset;
    } else if (offset >= maximum) {
      return maxOffset;
    } else {
      return SheetOffset.absolute(offset - layout.contentBaseline, relativeToBaseline: true);
    }
  }
}

/// A set of stops.
///
/// When the finger lifts, the sheet goes to the stop nearest where it is, or, for a release faster than
/// [minFlingSpeed], to the next stop in the direction of travel. With [flickProjection] set, it instead goes to the
/// stop nearest where the release would carry it in that many seconds (Apple's way: a slow release settles back, a
/// flick carries on), never further than the next stop.
class MultiSheetDetents implements SheetDetents {
  /// Creates detents from [snaps], in any order.
  const MultiSheetDetents({required this.snaps, this.minFlingSpeed = kMinFlingVelocity, this.flickProjection})
    : assert(flickProjection == null || flickProjection >= 0);

  /// The stops.
  final List<SheetOffset> snaps;

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  ///
  /// Not used when [flickProjection] is set.
  final double minFlingSpeed;

  /// When set, how far ahead in seconds the release's speed is projected to choose the stop.
  final double? flickProjection;

  @override
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity) {
    final result = _scanSnapOffsets(layout, offset);
    if (offset < result.min.resolve(layout)) {
      return result.min;
    } else if (offset > result.max.resolve(layout)) {
      return result.max;
    } else if (flickProjection case final double projection) {
      final projected = offset + velocity * projection;
      final target = _scanSnapOffsets(layout, projected).nearest;
      // Never past the next stop in the direction of travel.
      if (velocity > 0 && target.resolve(layout) > result.rightmost.resolve(layout)) return result.rightmost;
      if (velocity < 0 && target.resolve(layout) < result.leftmost.resolve(layout)) return result.leftmost;
      return target;
    } else if (velocity.abs() < minFlingSpeed) {
      return result.nearest;
    } else if (velocity < 0) {
      return result.leftmost;
    } else {
      return result.rightmost;
    }
  }

  @override
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout) {
    assert(snaps.isNotEmpty);
    if (snaps.length == 1) {
      return (snaps.first, snaps.first);
    }

    if (snaps.length == 2) {
      final first = snaps.first.resolve(layout);
      final second = snaps.last.resolve(layout);
      return first < second ? (snaps.first, snaps.last) : (snaps.last, snaps.first);
    }

    var minimum = snaps.first;
    var maximum = minimum;
    var resolvedMinimum = minimum.resolve(layout);
    var resolvedMaximum = resolvedMinimum;
    for (var index = 1; index < snaps.length; index++) {
      final resolved = snaps[index].resolve(layout);
      if (resolved < resolvedMinimum) {
        minimum = snaps[index];
        resolvedMinimum = resolved;
      } else if (resolved > resolvedMaximum) {
        maximum = snaps[index];
        resolvedMaximum = resolved;
      }
    }
    return (minimum, maximum);
  }

  /// Given a [layout] and an [offset], finds the minimum, maximum, nearest,
  /// leftmost, and rightmost offsets in the [snaps] list.
  ///
  /// Where:
  /// - `min` is the smallest offset.
  /// - `max` is the largest offset.
  /// - `nearest` is the offset that is closest to the `offset`.
  /// - `leftmost` is the offset that is the maximum offset that is less than
  ///   or equal to the `nearest`.
  /// - `rightmost` is the offset that is the minimum offset that is greater
  ///   than or equal to the `nearest`.
  ({SheetOffset min, SheetOffset max, SheetOffset nearest, SheetOffset leftmost, SheetOffset rightmost})
  _scanSnapOffsets(ViewportLayout layout, double offset) {
    assert(snaps.isNotEmpty);

    if (snaps.length == 1) {
      return (min: snaps.first, max: snaps.first, nearest: snaps.first, leftmost: snaps.first, rightmost: snaps.first);
    }

    if (snaps.length == 2) {
      final first = snaps.first.resolve(layout);
      final second = snaps.last.resolve(layout);

      final (minimum, maximum) = first < second ? (snaps.first, snaps.last) : (snaps.last, snaps.first);

      final firstDistance = (first - offset).abs();
      final secondDistance = (second - offset).abs();
      final nearest = firstDistance < secondDistance ? snaps.first : snaps.last;

      return (min: minimum, max: maximum, nearest: nearest, leftmost: minimum, rightmost: maximum);
    }

    if (snaps.length == 3) {
      final first = snaps[0];
      final second = snaps[1];
      final third = snaps[2];
      final rFirst = first.resolve(layout);
      final rSecond = second.resolve(layout);
      final rThird = third.resolve(layout);

      final minimum = rFirst < rSecond ? (rFirst < rThird ? first : third) : (rSecond < rThird ? second : third);
      final maximum = rFirst > rSecond ? (rFirst > rThird ? first : third) : (rSecond > rThird ? second : third);

      final firstDistance = (rFirst - offset).abs();
      final secondDistance = (rSecond - offset).abs();
      final thirdDistance = (rThird - offset).abs();
      final nearest = firstDistance < secondDistance
          ? (firstDistance < thirdDistance ? first : third)
          : (secondDistance < thirdDistance ? second : third);

      final SheetOffset leftmost;
      final SheetOffset rightmost;
      if (nearest == first) {
        leftmost = first;
        rightmost = second;
      } else if (nearest == second) {
        leftmost = first;
        rightmost = third;
      } else {
        assert(nearest == third);
        leftmost = second;
        rightmost = third;
      }

      return (min: minimum, max: maximum, nearest: nearest, leftmost: leftmost, rightmost: rightmost);
    }

    assert(snaps.length > 3);
    final sortedSnaps = [...snaps]..sort((a, b) => a.resolve(layout).compareTo(b.resolve(layout)));

    late int nearestIndex;
    late SheetOffset nearest;
    var nearestDistance = double.infinity;
    for (var index = 0; index < sortedSnaps.length; index++) {
      final snap = sortedSnaps[index];
      final distance = (snap.resolve(layout) - offset).abs();
      if (distance < nearestDistance) {
        nearestIndex = index;
        nearest = snap;
        nearestDistance = distance;
      }
    }

    return (
      min: sortedSnaps.first,
      max: sortedSnaps.last,
      nearest: nearest,
      leftmost: sortedSnaps[max(nearestIndex - 1, 0)],
      rightmost: sortedSnaps[min(nearestIndex + 1, sortedSnaps.length - 1)],
    );
  }
}

/// Ona's stops, after Apple's medium and large detents.
///
/// Content that fits on the screen rests whole, at its own height, alone. Longer content rests at [half] of the
/// screen or at full, its whole height up to the top of the viewport. While the keyboard is up (the sheet's bottom
/// margin is non-zero), the sheet rests at full alone, so a focused field is never hidden. A release picks its stop
/// by [flickProjection], as [MultiSheetDetents.flickProjection] does.
class AdaptiveSheetDetents implements SheetDetents {
  /// Creates Ona's adaptive stops.
  const AdaptiveSheetDetents({this.half = 0.5, this.flickProjection = 0.499})
    : assert(half > 0 && half < 1),
      assert(flickProjection >= 0);

  /// The lower stop of long content, as a fraction of the viewport's height.
  final double half;

  /// How far ahead in seconds a release's speed is projected to choose the stop.
  final double flickProjection;

  /// The stop the sheet opens at: [half] for long content, else its full height.
  SheetOffset get rest => _AdaptiveRest(half);

  @override
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout) => (rest, const SheetOffset(1));

  @override
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity) {
    final projected = offset + velocity * flickProjection;
    final low = rest.resolve(layout);
    final high = const SheetOffset(1).resolve(layout);
    return (projected - low).abs() <= (projected - high).abs() ? rest : const SheetOffset(1);
  }

  @override
  bool operator ==(Object other) =>
      other is AdaptiveSheetDetents && other.half == half && other.flickProjection == flickProjection;

  @override
  int get hashCode => Object.hash(half, flickProjection);
}

/// The lower stop of [AdaptiveSheetDetents]: [half] of the viewport for content longer than it, else the content's
/// full height (and full height while the keyboard is up).
@immutable
class _AdaptiveRest implements SheetOffset {
  const _AdaptiveRest(this.half);

  final double half;

  @override
  double resolve(ViewportLayout layout) {
    final room = layout.viewportSize.height - layout.viewportPadding.vertical - layout.contentMargin.vertical;
    final fits = layout.contentSize.height < room - 1;
    return fits || layout.contentMargin.bottom > 0
        ? const SheetOffset(1).resolve(layout)
        : layout.viewportSize.height * half;
  }

  @override
  bool operator ==(Object other) => other is _AdaptiveRest && other.half == half;

  @override
  int get hashCode => half.hashCode;
}
