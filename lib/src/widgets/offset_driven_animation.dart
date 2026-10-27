import 'package:flutter/animation.dart';

import '../foundation/controller.dart';
import '../foundation/model.dart';

/// An animation whose value follows the sheet's position: 0 at [startOffset], 1 at [endOffset].
///
/// Drive anything from where the sheet is, for example the opacity of a header that appears as it rises.
class SheetOffsetDrivenAnimation extends Animation<double> {
  /// Creates an animation driven by the sheet [controller] watches.
  SheetOffsetDrivenAnimation({
    required OnaSheetController controller,
    required this.initialValue,
    this.startOffset,
    this.endOffset,
  }) : _controller = controller,
       assert(initialValue >= 0.0 && initialValue <= 1.0);

  final OnaSheetController _controller;

  /// The value before the sheet is laid out.
  final double initialValue;

  /// Where the value is 0; the sheet's lowest stop when null.
  final SheetOffset? startOffset;

  /// Where the value is 1; the sheet's highest stop when null.
  final SheetOffset? endOffset;

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  double get value {
    final metrics = _controller.metrics;
    if (metrics == null) {
      return initialValue;
    }

    final startOffset = this.startOffset?.resolve(metrics) ?? metrics.minOffset;
    final endOffset = this.endOffset?.resolve(metrics) ?? metrics.maxOffset;
    final distance = endOffset - startOffset;

    if (distance.isFinite && distance > 0) {
      return ((metrics.offset - startOffset) / distance).clamp(0, 1);
    }

    return 1;
  }
}
