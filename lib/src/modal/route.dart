import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/float_comp.dart';
import '../foundation/model.dart';
import '../gestures/drag.dart';
import '../gestures/gesture_proxy.dart';
import '../widgets/viewport.dart';

const _minReleasedPageForwardAnimationTime = 300; // Milliseconds.
const Cubic _releasedPageForwardAnimationCurve = Curves.fastLinearToSlowEaseIn;

/// {@template modal_sheet_barrier_builder}
/// A builder for creating a custom modal barrier.
///
/// If provided, this builder is called instead of creating the default
/// [AnimatedModalBarrier]. The builder receives the route instance and
/// a dismiss callback, allowing customization of the barrier's
/// appearance and behavior.
///
/// The dismiss callback should be invoked when the user interacts with
/// the barrier to dismiss the modal (e.g., by tapping). The callback
/// will only dismiss the modal if [OnaBottomSheetPage.barrierDismissible] is
/// `true` and the route animation is completed.
///
/// If `null`, the default [AnimatedModalBarrier] is used with the
/// configured [OnaBottomSheetPage.barrierColor]. The default value is `null`.
/// {@endtemplate}
typedef OnaSheetBarrierBuilder<T> = Widget Function(ModalRoute<T> route, VoidCallback onDismissCallback);

/// Builds the [OnaSheetViewport] a modal sheet lives in, around [child].
typedef OnaSheetViewportBuilder = Widget Function(BuildContext context, Widget child);

/// A modal sheet as a [Page], for declarative navigation (Navigator 2.0 and routers built on it).
///
/// It behaves as [OnaBottomSheetRoute]; [child] is the sheet, typically an [OnaBottomSheet].
class OnaBottomSheetPage<T> extends Page<T> {
  /// Creates a page that shows [child] as a modal sheet.
  const OnaBottomSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.swipeDismissible = false,
    this.fullscreenDialog = false,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.dismissDuration,
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
    this.viewportBuilder,
    this.barrierBuilder,
    this.semanticsLabel,
    required this.child,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// Builds the viewport the sheet lives in; by default a plain [OnaSheetViewport].
  final OnaSheetViewportBuilder? viewportBuilder;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// Whether the route is a full-screen dialog (the route below then skips its own exit transition).
  final bool fullscreenDialog;

  /// The colour laid over the page behind the sheet.
  final Color? barrierColor;

  /// Whether a tap on the barrier closes the sheet.
  final bool barrierDismissible;

  /// What screen readers call the barrier.
  final String? barrierLabel;

  /// Whether a downward swipe can close the sheet.
  final bool swipeDismissible;

  /// How long the sheet takes to come in.
  final Duration transitionDuration;

  /// How long the sheet takes to go away without a swipe; [transitionDuration] when null.
  final Duration? dismissDuration;

  /// The curve the sheet comes in on, reversed on the way out.
  final Curve transitionCurve;

  /// How readily a swipe closes the sheet.
  final SwipeDismissSensitivity swipeDismissSensitivity;

  /// What screen readers call the sheet; the platform's "bottom sheet" label when null.
  final String? semanticsLabel;

  /// {@macro modal_sheet_barrier_builder}
  final OnaSheetBarrierBuilder<T>? barrierBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedBottomSheetRoute(page: this, fullscreenDialog: fullscreenDialog);
  }
}

class _PageBasedBottomSheetRoute<T> extends PageRoute<T> with OnaBottomSheetRouteMixin<T> {
  _PageBasedBottomSheetRoute({required OnaBottomSheetPage<T> page, super.fullscreenDialog}) : super(settings: page);

  OnaBottomSheetPage<T> get _page => settings as OnaBottomSheetPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  bool get swipeDismissible => _page.swipeDismissible;

  @override
  Curve get transitionCurve => _page.transitionCurve;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.dismissDuration ?? _page.transitionDuration;

  @override
  String? get semanticsLabel => _page.semanticsLabel;

  @override
  SwipeDismissSensitivity get swipeDismissSensitivity => _page.swipeDismissSensitivity;

  @override
  OnaSheetBarrierBuilder<T>? get barrierBuilder => _page.barrierBuilder;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildSheet(BuildContext context) => _page.child;

  @override
  Widget buildViewport(BuildContext context, Widget child) {
    return _page.viewportBuilder?.call(context, child) ?? super.buildViewport(context, child);
  }
}

/// A route that shows a sheet over the current page, with a barrier, swipe-to-close and back-gesture support.
///
/// [showOnaBottomSheet] pushes one styled by the [OnaBottomSheetTheme]; construct it directly for full control.
class OnaBottomSheetRoute<T> extends PageRoute<T> with OnaBottomSheetRouteMixin<T> {
  /// Creates a modal sheet route.
  OnaBottomSheetRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.viewportBuilder,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.swipeDismissible = false,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.dismissDuration,
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
    this.barrierBuilder,
    this.semanticsLabel,
  });

  /// Builds the sheet; it should return a sheet widget such as [OnaBottomSheet], not an [OnaSheetViewport], which
  /// the route adds itself.
  final WidgetBuilder builder;

  /// Builds the viewport the sheet lives in; by default a plain [OnaSheetViewport].
  final OnaSheetViewportBuilder? viewportBuilder;

  /// How long the route takes to go away when it is popped without a swipe; [transitionDuration] when null.
  final Duration? dismissDuration;

  @override
  final String? semanticsLabel;

  @override
  Duration get reverseTransitionDuration => dismissDuration ?? transitionDuration;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final bool swipeDismissible;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final Curve transitionCurve;

  @override
  final SwipeDismissSensitivity swipeDismissSensitivity;

  @override
  final OnaSheetBarrierBuilder<T>? barrierBuilder;

  @override
  Widget buildSheet(BuildContext context) {
    return builder(context);
  }

  @override
  Widget buildViewport(BuildContext context, Widget child) {
    return viewportBuilder?.call(context, child) ?? super.buildViewport(context, child);
  }
}

/// The behaviour every modal sheet route shares: the barrier, swipe-to-close, the transition, and the sheet's
/// visibility.
mixin OnaBottomSheetRouteMixin<T> on ModalRoute<T> {
  /// Whether a downward swipe can close the sheet.
  bool get swipeDismissible;

  /// What screen readers call the sheet; the platform's "bottom sheet" label when null.
  String? get semanticsLabel => null;

  /// The speed, in viewport heights per second, a swipe was released at when it closed the sheet; consumed by the
  /// pop's [createSimulation].
  double? _releaseSpeed;

  /// A swipe released into a close carries the sheet away at the finger's speed, never slower than an ordinary
  /// close; any other pop uses the [reverseTransitionDuration].
  @override
  Simulation? createSimulation({required bool forward}) {
    final speed = _releaseSpeed;
    _releaseSpeed = null;
    if (forward || speed == null || controller == null) return null;
    final ordinary = reverseTransitionDuration.inMicroseconds / Duration.microsecondsPerSecond;
    return _ReleaseSimulation(controller!.value, ordinary > 0 ? max(speed, 1 / ordinary) : speed);
  }

  /// The curve the sheet comes in on, reversed on the way out.
  Curve get transitionCurve;

  /// How readily a swipe closes the sheet.
  SwipeDismissSensitivity get swipeDismissSensitivity;

  @override
  bool get opaque => false;

  /// {@macro modal_sheet_barrier_builder}
  OnaSheetBarrierBuilder<T>? get barrierBuilder;

  // Provides access to the AnimationController of this route that is
  // marked as protected, allowing it to be used by SheetDismissible.
  AnimationController get _controller => controller!;

  /// The curve used for the transition animation.
  ///
  /// In the middle of a dismiss gesture drag,
  /// this returns [Curves.linear] to match the finger motion.
  @nonVirtual
  @visibleForTesting
  Curve get effectiveCurve => (navigator?.userGestureInProgress ?? false) ? Curves.linear : transitionCurve;

  /// Reports how much of a modal sheet is currently visible on the viewport.
  ///
  /// The [Animation.value] is the fraction (from 0 to 1, inclusively) of
  /// the sheet's height that lies within the viewport, for example:
  ///
  /// - `0`: the sheet is entirely outside the viewport.
  /// - `0.5`: the upper half is visible; the rest is below the viewport.
  /// - `1`: the entire sheet is within the viewport.
  ///
  /// It reflects both the route's transition animation (the push and
  /// pop animations, and the swipe-to-dismiss gesture) and the sheet's own
  /// position within the viewport (for example, dragging between snap points).
  ///
  /// A typical use is to tie the modal barrier built by
  /// [OnaBottomSheetRoute.barrierBuilder] to the sheet, so that the barrier fades
  /// out as the user drags the sheet down:
  ///
  /// ```dart
  /// OnaBottomSheetRoute<void>(
  ///   builder: (context) => RawSheet(child: ...),
  ///   barrierBuilder: (route, onDismiss) {
  ///     final visibility =
  ///         (route as OnaBottomSheetRouteMixin<void>).sheetVisibility;
  ///     return AnimatedModalBarrier(
  ///       onDismiss: onDismiss,
  ///       color: visibility.drive(
  ///         ColorTween(begin: Colors.transparent, end: Colors.black54),
  ///       ),
  ///     );
  ///   },
  /// );
  /// ```
  Animation<double> get sheetVisibility => _sheetVisibility;
  late final _SheetVisibilityNotifier _sheetVisibility;

  @override
  void install() {
    super.install();
    _sheetVisibility = _SheetVisibilityNotifier();
  }

  @override
  void dispose() {
    _sheetVisibility.dispose();
    super.dispose();
  }

  /// Builds the sheet the route shows.
  Widget buildSheet(BuildContext context);

  /// Builds the viewport around the sheet.
  Widget buildViewport(BuildContext context, Widget child) {
    return OnaSheetViewport(child: child);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final MaterialLocalizations? words = Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    return Semantics(
      // Names the sheet for screen readers, and lets their escape gesture close it when a tap outside would.
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticsLabel ?? words?.bottomSheetLabel,
      onDismiss: barrierDismissible ? () => navigator?.maybePop() : null,
      child: buildViewport(
        context,
        _SheetVisibilityObserver(
          route: this,
          child: _SheetDismissible(
            enabled: swipeDismissible,
            sensitivity: swipeDismissSensitivity,
            child: buildSheet(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionTween = Tween(begin: const Offset(0, 1), end: Offset.zero);
    return SlideTransition(
      position: animation.drive(transitionTween.chain(CurveTween(curve: effectiveCurve))),
      child: child,
    );
  }

  @override
  Widget buildModalBarrier() {
    void onDismiss() {
      if (animation!.isCompleted && !navigator!.userGestureInProgress) {
        navigator?.maybePop();
      }
    }

    if (barrierBuilder != null) {
      return barrierBuilder!(this, onDismiss);
    }

    final barrierColor = this.barrierColor;
    if (barrierColor != null && barrierColor.a != 0 && !offstage) {
      assert(barrierColor != barrierColor.withValues(alpha: 0));
      return AnimatedModalBarrier(
        onDismiss: onDismiss,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        color: _DefaultModalBarrierColorAnimation(
          transitionProgress: animation!,
          userGestureInProgress: () => navigator!.userGestureInProgress,
          sheetVisibility: _sheetVisibility,
          curve: barrierCurve,
          color: barrierColor,
        ),
      );
    } else {
      return ModalBarrier(
        onDismiss: onDismiss,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }
  }
}

/// Enables swipe-to-dismiss functionality for a modal sheet route.
///
/// Must be used as the content of a route that implements
/// [OnaBottomSheetRouteMixin], and must be an ancestor of the sheet.
class _SheetDismissible extends StatefulWidget {
  const _SheetDismissible({
    this.enabled = true,
    this.sensitivity = const SwipeDismissSensitivity(),
    required this.child,
  });

  final bool enabled;
  final SwipeDismissSensitivity sensitivity;
  final Widget child;

  @override
  State<_SheetDismissible> createState() => _SheetDismissibleState();
}

class _SheetDismissibleState extends State<_SheetDismissible> with SheetGestureProxyMixin {
  /// The global key for the [_SheetDismissible.child].
  ///
  /// Used to prevent the state of the [_SheetDismissible.child] from being
  /// discarded when the [_SheetDismissible.enabled] is dynamically changed.
  final GlobalKey<State<StatefulWidget>> _childGlobalKey = GlobalKey();

  late OnaBottomSheetRouteMixin<dynamic> _route;

  AnimationController get _transitionController => _route._controller;

  bool get _isUserGestureInProgress => _route.navigator!.userGestureInProgress;

  Size get _navigatorSize => _route.navigator!.context.size!;

  final List<_SheetPopScopeState<dynamic>> _popScopes = [];

  /// Whether the modal can be dismissed by the swipe gesture.
  ///
  /// The gesture is still available if [_isGestureEnabled] is true,
  /// even if this returns false.
  bool get _canPopByGesture => widget.enabled && _route.popDisposition == RoutePopDisposition.pop;

  /// Whether the gesture is available.
  ///
  /// The modal cannot be dismissed if [_canPopByGesture] is false,
  /// even if this returns true.
  bool get _isGestureEnabled => widget.enabled && _popScopes.every((it) => it.isGestureEnabled.value);

  void registerPopScope(_SheetPopScopeState<dynamic> popScope) {
    assert(!_popScopes.contains(popScope));
    popScope.isGestureEnabled.addListener(_onIsGestureEnabledMayChanged);
    _popScopes.add(popScope);
    _onIsGestureEnabledMayChanged();
  }

  void unregisterPopScope(_SheetPopScopeState<dynamic> popScope) {
    assert(_popScopes.contains(popScope));
    popScope.isGestureEnabled.removeListener(_onIsGestureEnabledMayChanged);
    _popScopes.remove(popScope);
    _onIsGestureEnabledMayChanged();
  }

  void _onIsGestureEnabledMayChanged() {
    // Since this method is invoked during the build phase due to changes
    // in the configuration of a descendant SheetPopScope, we need to
    // schedule another frame to ensure that the updated _isGestureEnabled
    // is also reflected in the state of this widget.
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (!_isDisposed) setState(() {});
    });
  }

  var _isDisposed = false;

  @override
  void dispose() {
    _popScopes.clear();
    super.dispose();
    _isDisposed = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(
      context.findAncestorStateOfType<_SheetDismissibleState>() == null,
      'Incorrect usage of SheetDismissible: '
      'it must not be used as a descendant of another SheetDismissible.',
    );

    final route = ModalRoute.of(context);

    assert(
      route != null && route is OnaBottomSheetRouteMixin<dynamic>,
      'Incorrect usage of SheetDismissible: '
      'it must be used as a descendant of a ModalRoute '
      'that implements OnaBottomSheetRouteMixin.',
    );

    _route = route! as OnaBottomSheetRouteMixin<dynamic>;
  }

  set _isUserGestureInProgress(bool inProgress) {
    if (inProgress && !_isUserGestureInProgress) {
      _route.navigator!.didStartUserGesture();
    } else if (!inProgress && _isUserGestureInProgress) {
      _route.navigator!.didStopUserGesture();
    }
  }

  @override
  SheetDragUpdateDetails onDragUpdate(SheetDragUpdateDetails details, Offset minPotentialDeltaConsumption) {
    final dragDelta = switch (details.axisDirection) {
      VerticalDirection.up => details.delta.dy,
      // Flip the sign of the delta here because all of the following
      // logic assumes that the axis direction is upwards.
      VerticalDirection.down => -1 * details.delta.dy,
    };

    final minPDC = minPotentialDeltaConsumption.dy;
    assert(details.delta.dy * minPDC >= 0);
    final double effectiveDragDelta;
    if (!_transitionController.isCompleted) {
      // Dominantly use the full pixels if it is in the middle of a transition.
      effectiveDragDelta = dragDelta;
    } else if (dragDelta < 0 &&
        FloatComp.distance(MediaQuery.devicePixelRatioOf(context)).isNotApprox(dragDelta, minPDC) &&
        MediaQuery.viewInsetsOf(context).bottom == 0) {
      // If the drag is downwards and the sheet may not consume the full pixels,
      // then use the remaining pixels as the effective drag delta.
      effectiveDragDelta = switch (details.axisDirection) {
        VerticalDirection.up => dragDelta - minPDC,
        VerticalDirection.down => dragDelta + minPDC,
      };
      assert(dragDelta * effectiveDragDelta >= 0);
    } else {
      // Otherwise, the drag delta doesn't change the transition progress.
      return super.onDragUpdate(details, minPotentialDeltaConsumption);
    }

    final viewport = _navigatorSize.height;
    final visibleViewport = viewport * _transitionController.value;
    assert(0 <= visibleViewport && visibleViewport <= viewport);
    final newVisibleViewport = (visibleViewport + effectiveDragDelta).clamp(0, viewport);

    assert(viewport > 0);
    final transitionProgress = newVisibleViewport / viewport;
    assert(0 <= transitionProgress && transitionProgress <= 1);
    _isUserGestureInProgress = transitionProgress < 1;
    _transitionController.value = transitionProgress;

    final viewportDelta = newVisibleViewport - visibleViewport;
    final unconsumedDragDelta = switch (details.axisDirection) {
      VerticalDirection.up => dragDelta - viewportDelta,
      VerticalDirection.down => viewportDelta - dragDelta,
    };

    return super.onDragUpdate(details.copyWith(deltaY: unconsumedDragDelta), minPotentialDeltaConsumption);
  }

  @override
  SheetDragEndDetails onDragEnd(SheetDragEndDetails details) {
    final wasHandled = _handleDragEnd(velocity: details.velocity, axisDirection: details.axisDirection);
    return wasHandled ? super.onDragEnd(details.copyWith(velocityX: 0, velocityY: 0)) : super.onDragEnd(details);
  }

  @override
  void onDragCancel(SheetDragCancelDetails details) {
    super.onDragCancel(details);
    _handleDragEnd(axisDirection: details.axisDirection, velocity: Velocity.zero);
  }

  bool _handleDragEnd({required Velocity velocity, required VerticalDirection axisDirection}) {
    if (!_isUserGestureInProgress || _transitionController.isAnimating) {
      return false;
    }

    final viewportHeight = _navigatorSize.height;
    final draggedDistance = viewportHeight * (1 - _transitionController.value);

    final effectiveVelocity = switch (axisDirection) {
      VerticalDirection.up => velocity.pixelsPerSecond.dy / viewportHeight,
      VerticalDirection.down => -1 * velocity.pixelsPerSecond.dy / viewportHeight,
    };

    final bool invokePop;
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      // The on-screen keyboard is open.
      invokePop = false;
    } else if (effectiveVelocity < 0) {
      // Flings down.
      invokePop = effectiveVelocity.abs() > widget.sensitivity.minFlingVelocityRatio;
    } else if (FloatComp.velocity(MediaQuery.devicePixelRatioOf(context)).isApprox(effectiveVelocity, 0)) {
      assert(draggedDistance >= 0);
      // Dragged down enough to dismiss.
      final viewPortState = OnaSheetViewportState.of(context);
      final currentOffset = viewPortState!.model.offset;

      final resolvedDismissalOffset = widget.sensitivity.dismissalOffset.resolve(viewPortState.model);

      final apparentOffset = currentOffset - draggedDistance;
      invokePop = resolvedDismissalOffset > apparentOffset;
    } else {
      // Flings up.
      invokePop = false;
    }

    final didPop = invokePop && _canPopByGesture;

    if (didPop) {
      // A fling keeps its speed on the way out.
      if (effectiveVelocity < 0) _route._releaseSpeed = effectiveVelocity.abs();
      _route.navigator!.pop();
    } else if (!_transitionController.isCompleted) {
      // The route won't be popped, so animate the transition
      // back to the origin.
      final fraction = 1.0 - _transitionController.value;
      final animationTime = max(
        (_route.transitionDuration.inMilliseconds * fraction).floor(),
        _minReleasedPageForwardAnimationTime,
      );

      const completedAnimationValue = 1.0;
      unawaited(
        _transitionController.animateTo(
          completedAnimationValue,
          duration: Duration(milliseconds: animationTime),
          curve: _releasedPageForwardAnimationCurve,
        ),
      );
    }

    // Reset the transition animation curve back to the default from linear
    // indirectly, by resetting the userGestureInProgress flag.
    // It is "indirect" because OnaBottomSheetRouteMixin.effectiveCurve returns
    // the linear curve when the userGestureInProgress flag is set to true.
    //
    // If the transition animation has not settled at either the start or end,
    // delay resetting the userGestureInProgress until the animation completes
    // to ensure the effectiveCurve remains linear during the animation,
    // matching the user's swipe motion. This is important to prevent the sheet
    // from jerking when the user swipes it down.
    //
    // Note: We cannot use AnimationController.isAnimating here to determine if
    // the transition animation is running, because, in Navigator 2.0,
    // the pop animation may not have started at this point even if
    // Navigator.pop() is called to pop the modal route.
    //
    // The following sequence of events illustrates why:
    // 1. Calling Navigator.pop() updates the internal page stack, triggering
    //    a rebuild of the Navigator. Note that the transition animation
    //    does not start here, so AnimationController.isAnimating returns false.
    // 2. The Navigator rebuilds with the new page stack.
    // 3. The modal route is removed from the Navigator's subtree.
    // 4. Route.didPop() is called, initiating the pop transition animation
    //    by calling AnimationController.reverse().
    if (_transitionController.isCompleted || _transitionController.isDismissed) {
      _isUserGestureInProgress = false;
    } else {
      late final AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          _isUserGestureInProgress = false;
          _transitionController.removeStatusListener(animationStatusCallback);
        }
      };
      _transitionController.addStatusListener(animationStatusCallback);
    }

    if (invokePop) {
      _route.onPopInvokedWithResult(didPop, null);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childGlobalKey, child: widget.child);
    return _isGestureEnabled ? SheetGestureProxy(proxy: this, child: child) : child;
  }
}

/// Configuration for the swipe-to-dismiss sensitivity of [OnaBottomSheetRoute],
/// [OnaBottomSheetPage], and related classes.
///
/// The modal will be dismissed under the following conditions:
/// - A downward fling gesture with the ratio of the velocity to the viewport
///   height that exceeds [minFlingVelocityRatio].
/// - A drag gesture ending with zero velocity, where the downward distance
///   exceeds the resolved [dismissalOffset].
class SwipeDismissSensitivity {
  /// Creates a swipe-to-dismiss sensitivity configuration.
  const SwipeDismissSensitivity({this.minFlingVelocityRatio = 2.0, this.dismissalOffset = const SheetOffset(0.3)});

  /// Minimum ratio of gesture velocity to viewport height required to
  /// trigger dismissal for a downward fling gesture.
  ///
  /// The viewport height is obtained from the `size` property of the
  /// navigator's [BuildContext] where the modal route belongs to.
  /// Therefore, the larger the viewport height, the higher the velocity
  /// required to dismiss the modal (and vice versa). This is to ensure that
  /// the swipe-to-dismiss behavior is consistent across different screen sizes.
  ///
  /// As a reference, the ratio of 1.0 corresponds to the velocity such that
  /// the user moves their finger from the top to the bottom of the screen
  /// in exactly 1 second.
  final double minFlingVelocityRatio;

  /// Defines the threshold in terms of SheetOffset, below which the sheet
  /// will be dismissed when the drag ends.
  ///
  /// With `SwipeDismissSensitivity(dismissalOffset: SheetOffset(0.4))`,
  /// the sheet will dismiss if 40% or less of the sheet is visible when
  /// the drag ends.
  ///
  /// With `SwipeDismissSensitivity(dismissalOffset: SheetOffset.absolute(200))`,
  /// the sheet will dismiss if 200 pixels or less of the sheet is
  /// visible when the drag ends.
  ///
  /// If the drag gesture ends with a non-zero velocity, it's treated as
  /// a fling gesture, and this value is not used.
  final SheetOffset dismissalOffset;
}

/// Manages the back navigation gesture for the current modal sheet.
///
/// This widget is a wrapper around [PopScope], providing additional control
/// over the swipe-to-dismiss gesture in a modal sheet.
/// The behavior of the modal sheet is determined by the [canPop] property and
/// whether [onPopInvokedWithResult] is provided. The table below describes
/// how the sheet behaves based on these properties:
///
/// | Behavior                        | Implementation |
/// |:------------------------------:|:--------------:|
/// | Can pop; Gesture is enabled    | `SheetPopScope(canPop: true)` |
/// | Cannot pop; Gesture is enabled | `SheetPopScope(canPop: false, onPopInvokedWithResult: nonNullCallback)` |
/// | Cannot pop; Gesture is disabled| `SheetPopScope(canPop: false, onPopInvokedWithResult: null)` |
///
/// Note that the gesture is always disabled if
/// [OnaBottomSheetRouteMixin.swipeDismissible] on the parent route is false.
///
/// Typically, this widget is placed above a sheet widget:
///
/// ```dart
/// OnaBottomSheetRoute(
///   swipeDismissible: true,
///   builder: (context) => SheetPopScope(
///     canPop: false,
///     onPopInvokedWithResult: (didPop, result) {...},
///     child: RawSheet(child: Container()),
///   ),
/// );
/// ```
///
/// However, it can also be placed deeper within the sheet's widget tree.
/// This is useful when you want to dynamically control gesture availability
/// in a widget's build method:
///
/// ```dart
/// class SheetContent extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // If false, the modal cannot be popped, and the gesture is also disabled
///     // (and vice versa).
///     final canPopByGesture = ...;
///     return SheetPopScope(
///       canPop: canPopByGesture,
///       onPopInvokedWithResult: canPopByGesture
///         ? (didPop, result) {...}
///         : null,
///       child: RawSheet(child: Container()),
///     );
///   }
/// }
/// ```
///
/// ## Compatibility with PopScope
///
/// While [SheetPopScope] offers fine-grained control, the standard [PopScope]
/// widget can also manage a modal sheet's dismissibility. However, [PopScope]
/// lacks the ability to control the swipe-to-dismiss gesture.
///
/// Assuming [OnaBottomSheetRouteMixin.swipeDismissible] is `true`, [PopScope]
/// behaves similarly to [SheetPopScope] in the following cases:
///
/// | Behavior                        | Implementation             |
/// |:------------------------------:|:--------------------------:|
/// | Can pop; Gesture is enabled    | `PopScope(canPop: true)`   |
/// | Cannot pop; Gesture is enabled | `PopScope(canPop: false)`  |
/// | Cannot pop; Gesture is disabled| ❌ Not possible             |
///
/// Note that the first two cases are equivalent to [SheetPopScope],
/// but the third is not possible with [PopScope].
class SheetPopScope<T> extends StatefulWidget {
  /// Creates a widget that controls the pop behavior of a modal sheet.
  const SheetPopScope({super.key, this.canPop = true, this.onPopInvokedWithResult, required this.child});

  /// When false, blocks the current route from being popped.
  ///
  /// Even if this is false, the swipe gesture is enabled, if
  /// [onPopInvokedWithResult] is not null and the parent
  /// [OnaBottomSheetRouteMixin.swipeDismissible] is true.
  ///
  /// See [PopScope.canPop] for more details.
  final bool canPop;

  /// A callback that is called when a pop is attempted on the current route,
  /// including when the swipe gesture is performed.
  ///
  /// If this is not null and the parent [OnaBottomSheetRouteMixin.swipeDismissible]
  /// is true, the swipe gesture is enabled even if [canPop] is false.
  ///
  /// See [PopScope.onPopInvokedWithResult] for more details.
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  /// The widget below this widget in the tree.
  final Widget child;

  bool get _isGestureEnabled => canPop || onPopInvokedWithResult != null;

  @override
  State<SheetPopScope<T>> createState() => _SheetPopScopeState<T>();
}

class _SheetPopScopeState<T> extends State<SheetPopScope<T>> {
  late final ValueNotifier<bool> isGestureEnabled;
  _SheetDismissibleState? _sheetDismissible;

  @override
  void initState() {
    super.initState();
    isGestureEnabled = ValueNotifier(widget._isGestureEnabled);
  }

  @override
  void dispose() {
    _sheetDismissible?.unregisterPopScope(this);
    isGestureEnabled.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sheetDismissible = context.findAncestorStateOfType<_SheetDismissibleState>();
    if (sheetDismissible != _sheetDismissible) {
      _sheetDismissible?.unregisterPopScope(this);
      _sheetDismissible = sheetDismissible?..registerPopScope(this);
    }
  }

  @override
  void didUpdateWidget(SheetPopScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    isGestureEnabled.value = widget._isGestureEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: widget.canPop, onPopInvokedWithResult: widget.onPopInvokedWithResult, child: widget.child);
  }
}

class _SheetVisibilityNotifier extends Animation<double> with ChangeNotifier {
  /// The fraction of the sheet's height that is visible in the viewport,
  /// ranging from 0 (entirely hidden) to 1 (entirely visible).
  @override
  double get value => _visibility;
  double _visibility = 0;

  /// Visibility threshold under which the swipe-to-dismiss action is triggered.
  double get swipeToDismissThreshold => _threshold;
  double _threshold = 1;

  void _updateVisibility(double visibility) {
    if (visibility != _visibility) {
      _visibility = visibility;
      notifyListeners();
    }
  }

  void didChangeVisualSheetPosition(SheetMetrics metrics, double transitionProgress) {
    final sheetHeight = metrics.size.height;
    if (sheetHeight <= 0) {
      _threshold = 1;
      _updateVisibility(0);
      return;
    }
    // The route transition slides the entire viewport, and thus the sheet,
    // downward by this amount.
    final viewportHeight = metrics.viewportSize.height;
    final translation = (1 - transitionProgress) * viewportHeight;
    final sheetTop = (viewportHeight - metrics.offset) + translation;
    _threshold = (metrics.minOffset / sheetHeight).clamp(0.0, 1.0);
    _updateVisibility(((viewportHeight - sheetTop) / sheetHeight).clamp(0.0, 1.0));
  }

  /// Always [AnimationStatus.forward], regardless of the direction in which
  /// the [value] is changing.
  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    // status will never change.
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    // status will never change.
  }
}

class _SheetVisibilityObserver extends StatefulWidget {
  const _SheetVisibilityObserver({required this.route, required this.child});

  final OnaBottomSheetRouteMixin<dynamic> route;
  final Widget child;

  @override
  State<_SheetVisibilityObserver> createState() => _SheetVisibilityObserverState();
}

class _SheetVisibilityObserverState extends State<_SheetVisibilityObserver> {
  Animation<double> get _transition => widget.route.animation!;

  SheetModelView? _model;

  @override
  void initState() {
    super.initState();
    _transition.addListener(_invalidateVisibility);
  }

  @override
  void dispose() {
    _transition.removeListener(_invalidateVisibility);
    _model?.removeListener(_invalidateVisibility);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = OnaSheetViewportState.of(context)!.model;
    _model?.removeListener(_invalidateVisibility);
    _model = model..addListener(_invalidateVisibility);
    _invalidateVisibility();
  }

  void _invalidateVisibility() {
    final model = _model;
    if (model != null && model.hasMetrics && !widget.route.offstage) {
      widget.route._sheetVisibility.didChangeVisualSheetPosition(
        model,
        widget.route.effectiveCurve.transform(_transition.value),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _DefaultModalBarrierColorAnimation extends Animation<Color> {
  _DefaultModalBarrierColorAnimation({
    required this.transitionProgress,
    required this.userGestureInProgress,
    required this.sheetVisibility,
    required this.curve,
    required this.color,
  }) : _transparentColor = color.withAlpha(0);

  final Animation<double> transitionProgress;
  final ValueGetter<bool> userGestureInProgress;
  final _SheetVisibilityNotifier sheetVisibility;
  final Curve curve;
  final Color color;
  final Color _transparentColor;

  @override
  void addListener(VoidCallback listener) => transitionProgress.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => transitionProgress.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) => transitionProgress.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) => transitionProgress.removeStatusListener(listener);

  @override
  AnimationStatus get status => transitionProgress.status;

  @override
  Color get value {
    double opacity;
    if (userGestureInProgress()) {
      opacity = sheetVisibility.value;
      if (sheetVisibility.swipeToDismissThreshold case final t when t > 0) {
        opacity = (opacity / t).clamp(0.0, 1.0);
      }
    } else {
      opacity = curve.transform(transitionProgress.value);
    }

    return Color.lerp(_transparentColor, color, opacity)!;
  }
}

/// Carries a released sheet off screen at a constant speed (in route-animation units per second).
class _ReleaseSimulation extends Simulation {
  _ReleaseSimulation(this._start, this._speed) : assert(_speed > 0);

  final double _start;
  final double _speed;

  @override
  double x(double time) => max(_start - _speed * time, 0);

  @override
  double dx(double time) => x(time) > 0 ? -_speed : 0;

  @override
  bool isDone(double time) => x(time) <= 0;
}
