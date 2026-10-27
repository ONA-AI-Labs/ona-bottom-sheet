import 'dart:math' as math;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart'
    show BouncingScrollPhysics, Curves, ScrollSpringSimulation, Simulation, SpringDescription;

import '../foundation/double_utils.dart';
import '../foundation/float_comp.dart';
import '../foundation/model.dart';
import 'detents.dart';

/// The default [SpringDescription] used by [SheetPhysics] subclasses.
///
/// This spring has the same configuration as the resulting spring
/// from the [SpringDescription.withDampingRatio] constructor with
/// a ratio of `1.1`, a mass of `0.5`, and a stiffness of `100.0`.
const _kDefaultSheetSpring = SpringDescription(
  mass: 0.5,
  stiffness: 100.0,
  // Use a pre-calculated value to define the spring as a const variable.
  // See the implementation of withDampingRatio() for the formula.
  damping: 15.5563491861, // 1.1 * 2.0 * sqrt(0.5 * 100.0)
);

/// The spring an Ona sheet settles on: non-bouncy, with a 0.35 s response.
///
/// Mass 1, stiffness (2π / 0.35)² and damping 4π / 0.35, which makes it critically damped (damping ratio 1). It
/// covers 87% of the way to a stop in 200 ms, against 73% for [RawSheet]'s neutral, overdamped default, and is what
/// [OnaSheetMotion.settle] defaults to.
const SpringDescription kOnaSheetSpring = SpringDescription(mass: 1, stiffness: 322.3, damping: 35.9);

/// The default [SheetPhysics] of a [RawSheet].
const kDefaultSheetPhysics = BouncingSheetPhysics();

/// How a sheet responds to drags past its bounds, and how it settles when let go.
///
/// [ClampingSheetPhysics] keeps it within its stops; [BouncingSheetPhysics] lets it stretch and spring back.
abstract class SheetPhysics {
  /// Allows subclasses to be const.
  const SheetPhysics();

  /// The minimum amount of pixel distance drags must move by to start motion
  /// the first time or after each time the drag motion stopped.
  ///
  /// If null, no minimum threshold is enforced.
  double? get dragStartDistanceMotionThreshold => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => const BouncingScrollPhysics().dragStartDistanceMotionThreshold,
    _ => null,
  };

  /// The part of a drag of [delta] that these physics would not apply to the sheet.
  double computeOverflow(double delta, SheetMetrics metrics);

  /// How far the sheet actually moves for a drag of [delta].
  double applyPhysicsToOffset(double delta, SheetMetrics metrics);

  /// The motion after the finger lifts at [velocity]: towards the stop [detents] picks, or null to stay put.
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics, SheetDetents detents);
}

/// A mixin that provides default implementations for [SheetPhysics] methods.
mixin SheetPhysicsMixin on SheetPhysics {
  /// The spring the sheet settles on.
  SpringDescription get spring => _kDefaultSheetSpring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    final newOffset = metrics.offset + delta;
    if (newOffset > metrics.maxOffset) {
      return math.min(newOffset - metrics.maxOffset, delta);
    } else if (newOffset < metrics.minOffset) {
      return math.max(newOffset - metrics.minOffset, delta);
    } else {
      return 0;
    }
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    if (delta > 0 && metrics.offset < metrics.maxOffset) {
      // Prevent the offset from going beyond the maximum value.
      return math.min(metrics.maxOffset, metrics.offset + delta) - metrics.offset;
    } else if (delta < 0 && metrics.offset > metrics.minOffset) {
      // Prevent the offset from going beyond the minimum value.
      return math.max(metrics.minOffset, metrics.offset + delta) - metrics.offset;
    } else {
      return 0;
    }
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics, SheetDetents detents) {
    // Ensure that this method always uses the default implementation
    // of findSettledPosition.
    final snap = detents.getSnapOffset(metrics, metrics.offset, velocity).resolve(metrics);

    if (FloatComp.distance(metrics.devicePixelRatio).isNotApprox(snap, metrics.offset)) {
      final direction = (snap - metrics.offset).sign;
      return ScrollSpringSimulation(
        spring,
        metrics.offset,
        snap,
        // The simulation velocity is intentionally set to 0 if the velocity is
        // is in the opposite direction of the destination, as flinging up an
        // over-dragged sheet or flinging down an under-dragged sheet tends to
        // cause unstable motion.
        velocity.sign == direction ? velocity : 0.0,
      );
    }

    return null;
  }
}

/// A [SheetPhysics] that keeps the sheet within [SheetMetrics.minOffset] and
/// [SheetMetrics.maxOffset]: once it reaches its highest stop, a drag further up
/// does not move it.
class ClampingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  /// Creates physics that never let the sheet past its bounds.
  const ClampingSheetPhysics({this.spring = _kDefaultSheetSpring});

  @override
  final SpringDescription spring;
}

/// A [SheetPhysics] that allows the sheet to go beyond the offset bounds
/// defined by [SheetMetrics.minOffset] and [SheetMetrics.maxOffset].
///
/// How far it goes is set by [bounceExtent] and how hard it pulls back by
/// [resistance]; where it comes to rest is chosen by the sheet's [SheetDetents].
class BouncingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  /// Creates physics that let the sheet stretch past its bounds and spring back.
  const BouncingSheetPhysics({this.bounceExtent = 120, this.resistance = 6, this.spring = _kDefaultSheetSpring})
    : assert(bounceExtent >= 0);

  /// Factor that controls how easy/hard it is to overdrag the sheet.
  ///
  /// The higher this value, the harder it is to reach the offset
  /// of [SheetMetrics.maxOffset] plus [bounceExtent] pixels if dragged upwards,
  /// or the offset of [SheetMetrics.minOffset] minus [bounceExtent] pixels
  /// if dragged downwards.
  ///
  /// This value can be negative.
  final double resistance;

  /// The maximum number of pixels that the sheet can be overdragged.
  ///
  /// See also [resistance], which controls how easy/hard it is to overdrag the sheet.
  final double bounceExtent;

  @override
  final SpringDescription spring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    return 0;
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    final minOffset = metrics.minOffset;
    final maxOffset = metrics.maxOffset;
    final currentOffset = metrics.offset;
    final unconstrainedNewOffset = currentOffset + delta;

    // A part of or the entire delta that is not affected by friction.
    // If the current offset plus the delta exceeds the content bounds,
    // only the exceeding part is affected by friction. Otherwise, friction
    // is not applied to the offset at all.
    final double zeroFrictionDelta;
    if (delta < 0 && currentOffset > minOffset && unconstrainedNewOffset < minOffset) {
      zeroFrictionDelta = minOffset - currentOffset;
    } else if (delta > 0 && currentOffset < maxOffset && unconstrainedNewOffset > maxOffset) {
      zeroFrictionDelta = maxOffset - currentOffset;
    } else {
      zeroFrictionDelta = 0.0;
    }

    final cmp = FloatComp.distance(metrics.devicePixelRatio);
    if (cmp.isApprox(zeroFrictionDelta, delta) ||
        // The friction is also not applied if the motion
        // direction is towards the content bounds.
        (currentOffset > maxOffset && delta < 0) ||
        (currentOffset < minOffset && delta > 0)) {
      return delta;
    }

    var newOffset = currentOffset + zeroFrictionDelta;
    var consumedDelta = zeroFrictionDelta;
    while (consumedDelta.abs() < delta.abs()) {
      // We divide the delta into smaller fragments and apply friction to each
      // fragment in sequence. This ensures that the friction is not too small
      // if the delta is too large relative to the exceeding pixels, preventing
      // the sheet from slipping too far.
      final fragment = (delta - consumedDelta).clamp(-kTouchSlop, kTouchSlop);
      final overflowPastStart = math.max(minOffset - (newOffset + fragment), 0.0);
      final overflowPastEnd = math.max(newOffset + fragment - maxOffset, 0.0);
      final overflowPast = math.max(overflowPastStart, overflowPastEnd);
      assert(overflowPast >= 0);
      final overflowFraction = (overflowPast / bounceExtent).clamp(0.0, 1.0);

      // The more the sheet is overdragged, the harder it is to drag further.
      final double frictionFactor;
      if (cmp.isNotApprox(resistance, 0)) {
        frictionFactor = (1.0 - math.exp(-1 * resistance * overflowFraction)) / (1.0 - math.exp(-1 * resistance));
      } else {
        // Linear map
        frictionFactor = overflowFraction;
      }

      newOffset += fragment * (1.0 - frictionFactor);
      consumedDelta += fragment;
    }

    return newOffset - currentOffset;
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics, SheetDetents detents) {
    final snap = detents.getSnapOffset(metrics, metrics.offset, velocity).resolve(metrics);

    if (FloatComp.distance(metrics.devicePixelRatio).isApprox(snap, metrics.offset)) {
      return null;
    }

    final overdragPastStart = math.max(metrics.minOffset - metrics.offset, 0.0);
    final overdragPastEnd = math.max(metrics.offset - metrics.maxOffset, 0.0);
    final overdragPast = math.max(overdragPastStart, overdragPastEnd);
    final overdragFraction = bounceExtent != 0 ? math.min(overdragPast / bounceExtent, 1.0) : 1.0;

    // A lower bounceExtent or higher resistance reduces the maximum
    // initial velocity of the ballistic animation. This ensures that a sheet
    // that is harder to overdrag also bounces less when flung up or down.
    //
    // If the sheet is overdragged and the fling velocity is toward the opposite
    // direction of the snap point, the maximum velocity is also reduced based
    // on how much the sheet is overdragged (the further the sheet is
    // overdragged, the more the maximum velocity is reduced).
    const maxVelocityCoefficient = 200.0;
    final maxVelocityLimit = bounceExtent / resistance * maxVelocityCoefficient;
    final snapDirection = (snap - metrics.offset).sign;
    final velocityEasingFactor = velocity.sign == snapDirection ? 0.0 : Curves.easeOutExpo.transform(overdragFraction);
    final effectiveVelocity = velocity.clampAbs(maxVelocityLimit * (1.0 - velocityEasingFactor));

    return ScrollSpringSimulation(spring, metrics.offset, snap, effectiveVelocity);
  }
}
