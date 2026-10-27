import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/activity.dart';
import '../foundation/controller.dart';
import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import '../gestures/draggable.dart';
import '../gestures/gesture_proxy.dart';
import '../physics/detents.dart';
import '../physics/physics.dart';
import '../scroll/scrollable.dart';
import 'viewport.dart';

class _DraggableScrollableSheetModelConfig extends SheetModelConfig {
  const _DraggableScrollableSheetModelConfig({
    required super.physics,
    required super.detents,
    required super.gestureProxy,
    required this.scrollConfiguration,
  });

  final SheetScrollConfiguration scrollConfiguration;

  @override
  _DraggableScrollableSheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetDetents? detents,
    SheetGestureProxyMixin? gestureProxy,
    SheetScrollConfiguration? scrollConfiguration,
  }) {
    return _DraggableScrollableSheetModelConfig(
      physics: physics ?? this.physics,
      detents: detents ?? this.detents,
      gestureProxy: gestureProxy ?? this.gestureProxy,
      scrollConfiguration: scrollConfiguration ?? this.scrollConfiguration,
    );
  }
}

class _DraggableScrollableSheetModel extends SheetModel<_DraggableScrollableSheetModelConfig>
    with ScrollAwareSheetModelMixin {
  _DraggableScrollableSheetModel(super.context, super.config, {required SheetOffset initialOffset}) {
    beginActivity(InitialSheetActivity(preferredInitialOffset: initialOffset));
  }

  @override
  SheetScrollConfiguration get scrollConfiguration => config.scrollConfiguration;
}

class OnaBottomSheet extends StatelessWidget {
  const OnaBottomSheet({
    super.key,
    this.initialOffset = const SheetOffset(1),
    this.physics,
    this.detents = const SheetDetents.single(snap: SheetOffset(1)),
    this.controller,
    this.scrollConfiguration = SheetScrollConfiguration.disabled,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.decoration = const DefaultSheetDecoration(),
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetOffset initialOffset;

  /// {@macro SheetPosition.physics}
  final SheetPhysics? physics;

  final SheetDetents detents;

  /// An object that can be used to control and observe the sheet height.
  final OnaSheetController? controller;

  /// Controls how the sheet integrates with scrollable content.
  ///
  /// Set to [SheetScrollConfiguration.disabled] to prevent the sheet position
  /// from being synchronized with scroll views inside the sheet.
  final SheetScrollConfiguration scrollConfiguration;

  /// Controls how the sheet responds to drag gestures.
  ///
  /// Set to [SheetDragConfiguration.disabled] to prevent the sheet from
  /// being dragged.
  final SheetDragConfiguration dragConfiguration;

  final SheetDecoration decoration;

  /// {@macro viewport.BareSheet.padding}
  final EdgeInsets padding;

  /// The content of the sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      controller: controller ?? DefaultOnaSheetController.maybeOf(context),
      factory: _createModel,
      config: _DraggableScrollableSheetModelConfig(
        physics: physics ?? kDefaultSheetPhysics,
        detents: detents,
        gestureProxy: SheetGestureProxy.maybeOf(context),
        scrollConfiguration: scrollConfiguration,
      ),
      child: BareSheet(
        decoration: decoration,
        padding: padding,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: scrollConfiguration,
          dragConfiguration: dragConfiguration,
          child: child,
        ),
      ),
    );
  }

  _DraggableScrollableSheetModel _createModel(SheetContext context, _DraggableScrollableSheetModelConfig config) {
    return _DraggableScrollableSheetModel(context, config, initialOffset: initialOffset);
  }
}

@internal
class DraggableScrollableSheetContent extends StatefulWidget {
  const DraggableScrollableSheetContent({
    super.key,
    required this.scrollConfiguration,
    required this.dragConfiguration,
    required this.child,
  });

  final SheetScrollConfiguration scrollConfiguration;

  final SheetDragConfiguration dragConfiguration;

  final Widget child;

  @override
  State<DraggableScrollableSheetContent> createState() => _DraggableScrollableSheetContentState();
}

class _DraggableScrollableSheetContentState extends State<DraggableScrollableSheetContent> {
  SheetScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.scrollConfiguration != SheetScrollConfiguration.disabled) {
      _scrollController = _createScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableScrollableSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollConfiguration != SheetScrollConfiguration.disabled) {
      _scrollController ??= _createScrollController();
    }
  }

  SheetScrollController _createScrollController() {
    return SheetScrollController();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SheetDraggable(configuration: widget.dragConfiguration, child: widget.child);
    if (_scrollController case final controller?) {
      result = SheetScrollable(controller: controller, child: result);
    }
    return result;
  }
}
