import 'package:flutter/animation.dart';

import '../foundation/controller.dart';
import '../foundation/model.dart';

class SheetOffsetDrivenAnimation extends Animation<double> {
  SheetOffsetDrivenAnimation({
    required OnaSheetController controller,
    required this.initialValue,
    this.startOffset,
    this.endOffset,
  }) : _controller = controller,
       assert(initialValue >= 0.0 && initialValue <= 1.0);

  final OnaSheetController _controller;
  final double initialValue;
  final SheetOffset? startOffset;
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
