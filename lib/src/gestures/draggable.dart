import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/model.dart';
import '../foundation/model_owner.dart';

/// Defines how a sheet should respond to drag gestures.
abstract class SheetDragConfiguration {
  /// Creates a [SheetDragConfiguration].
  ///
  /// The [hitTestBehavior] defaults to [HitTestBehavior.opaque] and the [dragStartBehavior] to
  /// [DragStartBehavior.down].
  const factory SheetDragConfiguration({
    HitTestBehavior hitTestBehavior,
    Set<PointerDeviceKind>? deviceKinds,
    DragStartBehavior dragStartBehavior,
  }) = _StaticSheetDragConfiguration;

  /// A [SheetDragConfiguration] that disables dragging.
  static const SheetDragConfiguration disabled = _SheetDragConfigurationDisabled.instance;

  /// Defines how a sheet with this configuration should behave
  /// during hit-testing.
  ///
  /// Returning `null` means dragging is disabled.
  HitTestBehavior? get hitTestBehavior;

  /// The pointer device kinds that the sheet responds to.
  ///
  /// When `null`, the sheet uses the drag devices from the nearest
  /// ancestor [ScrollConfiguration].
  Set<PointerDeviceKind>? get deviceKinds;

  /// Where a drag starts from once the finger has moved past the touch slop.
  ///
  /// [DragStartBehavior.down], the default, starts it where the finger went down, so the sheet catches up and then
  /// follows the finger exactly, as native sheets do. [DragStartBehavior.start] starts it where the slop was
  /// passed, which leaves the sheet trailing the finger by the slop for the whole drag.
  ///
  /// The slop itself comes from the ambient [MediaQueryData.gestureSettings].
  DragStartBehavior get dragStartBehavior;
}

@immutable
class _StaticSheetDragConfiguration implements SheetDragConfiguration {
  const _StaticSheetDragConfiguration({
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.deviceKinds,
    this.dragStartBehavior = DragStartBehavior.down,
  });

  @override
  final HitTestBehavior hitTestBehavior;

  @override
  final Set<PointerDeviceKind>? deviceKinds;

  @override
  final DragStartBehavior dragStartBehavior;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _StaticSheetDragConfiguration &&
            runtimeType == other.runtimeType &&
            hitTestBehavior == other.hitTestBehavior &&
            dragStartBehavior == other.dragStartBehavior &&
            setEquals(deviceKinds, other.deviceKinds);
  }

  @override
  int get hashCode => Object.hash(runtimeType, hitTestBehavior, deviceKinds, dragStartBehavior);
}

@immutable
class _SheetDragConfigurationDisabled implements SheetDragConfiguration {
  const _SheetDragConfigurationDisabled._();

  static const instance = _SheetDragConfigurationDisabled._();

  @override
  HitTestBehavior? get hitTestBehavior => null;

  @override
  Set<PointerDeviceKind>? get deviceKinds => null;

  @override
  DragStartBehavior get dragStartBehavior => DragStartBehavior.down;

  @override
  bool operator ==(Object other) {
    assert(identical(this, instance), 'There should only be one instance of disabled configuration');
    return identical(this, other);
  }

  @override
  int get hashCode => identityHashCode(this);
}

@internal
class SheetDraggable extends StatefulWidget {
  const SheetDraggable({super.key, required this.configuration, required this.child});

  final SheetDragConfiguration configuration;
  final Widget child;

  @override
  State<SheetDraggable> createState() => _SheetDraggableState();
}

class _SheetDraggableState extends State<SheetDraggable> {
  VerticalDragGestureRecognizer? _gestureRecognizer;
  SheetModel? _model;
  Drag? _currentDrag;

  Set<PointerDeviceKind> get _effectiveDeviceKinds =>
      widget.configuration.deviceKinds ?? ScrollConfiguration.of(context).dragDevices;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context);
    _gestureRecognizer ??= VerticalDragGestureRecognizer(debugOwner: kDebugMode ? runtimeType : null)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
    _configureRecognizer();
  }

  @override
  void didUpdateWidget(SheetDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureRecognizer();
  }

  // The slop comes from MediaQuery, as for Flutter's own scroll views, so one setting governs both.
  void _configureRecognizer() {
    _gestureRecognizer!
      ..supportedDevices = _effectiveDeviceKinds
      ..dragStartBehavior = widget.configuration.dragStartBehavior
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
  }

  @override
  void dispose() {
    _model = null;
    _disposeDrag();
    _gestureRecognizer?.dispose();
    super.dispose();
  }

  void _disposeDrag() {
    _currentDrag = null;
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_currentDrag == null);
    if (widget.configuration != SheetDragConfiguration.disabled) {
      _currentDrag = _model?.drag(details, _disposeDrag);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDrag?.update(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    _currentDrag?.end(details);
    _disposeDrag();
  }

  void _handleDragCancel() {
    _currentDrag?.cancel();
    _disposeDrag();
  }

  @override
  Widget build(BuildContext context) {
    return _DragGestureListener(
      dragConfiguration: widget.configuration,
      gestureRecognizer: _gestureRecognizer!,
      child: widget.child,
    );
  }
}

class _DragGestureListener extends SingleChildRenderObjectWidget {
  const _DragGestureListener({required this.dragConfiguration, required this.gestureRecognizer, required super.child});

  final SheetDragConfiguration dragConfiguration;
  final GestureRecognizer gestureRecognizer;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDragGestureListener(dragConfiguration: dragConfiguration, gestureRecognizer: gestureRecognizer);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderDragGestureListener renderObject) {
    renderObject
      ..dragConfiguration = dragConfiguration
      ..gestureRecognizer = gestureRecognizer;
  }
}

class _RenderDragGestureListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderDragGestureListener({required this.dragConfiguration, required this.gestureRecognizer})
    : super(
        // This value won't be used on runtime.
        behavior: HitTestBehavior.deferToChild,
      );

  SheetDragConfiguration dragConfiguration;
  GestureRecognizer gestureRecognizer;

  @override
  HitTestBehavior get behavior {
    return dragConfiguration.hitTestBehavior ?? HitTestBehavior.deferToChild;
  }

  @override
  set behavior(HitTestBehavior value) {
    assert(false, 'Should not be used');
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (dragConfiguration.hitTestBehavior == null) {
      // When drag is disabled, still hit-test children so that
      // child widgets (e.g. buttons) remain interactive.
      return size.contains(position) && hitTestChildren(result, position: position);
    }
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return dragConfiguration.hitTestBehavior != null && super.hitTestSelf(position);
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      gestureRecognizer.addPointer(event);
    } else if (event is PointerPanZoomStartEvent) {
      gestureRecognizer.addPointerPanZoom(event);
    }
  }
}
