/// @docImport '../modal/show.dart';
library;

import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/material.dart';

import '../foundation/controller.dart';
import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import '../gestures/draggable.dart';
import '../physics/detents.dart';
import '../physics/physics.dart';
import '../scroll/scrollable.dart';
import '../theme/theme.dart';
import 'decorations.dart';
import 'keyboard_dismissible.dart';
import 'raw_sheet.dart';
import 'viewport.dart';

/// Ona's bottom sheet: a [RawSheet] dressed and tuned by the ambient [OnaBottomSheetTheme].
///
/// Out of the box it rests where Apple's sheets do ([SheetDetents.adaptive]: whole when its content fits, else half
/// and full), settles on the theme's spring, never moves past its highest stop, shares one drag with a scroll view
/// inside it, follows the finger exactly from the theme's touch slop, rises above the keyboard and lets a drag down
/// put the keyboard away. Every one of those can be changed here.
///
/// Show it modally with [showOnaBottomSheet], or keep it on a screen by placing it in an [OnaSheetViewport]:
///
/// ```dart
/// Stack(children: [
///   const MapView(),
///   OnaSheetViewport(
///     child: OnaBottomSheet(
///       detents: SheetDetents(snaps: [SheetOffset.absolute(120), SheetOffset(1)]),
///       child: const PlacesList(),
///     ),
///   ),
/// ]);
/// ```
class OnaBottomSheet extends StatelessWidget {
  /// Creates a sheet showing [child].
  const OnaBottomSheet({
    super.key,
    required this.child,
    this.detents,
    this.initialOffset,
    this.controller,
    this.physics,
    this.backgroundColor,
    this.cornerRadius,
    this.decoration,
    this.scrollConfiguration = const SheetScrollConfiguration(
      scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
      delegateUnhandledOverscrollToChild: true,
    ),
    this.dragConfiguration = const SheetDragConfiguration(),
    this.keyboardDismissBehavior = const SheetKeyboardDismissBehavior.onDragDown(),
    this.avoidsKeyboard = true,
  });

  /// The sheet's content, typically an [OnaSheetScaffold].
  final Widget child;

  /// Where the sheet can rest; [SheetDetents.adaptive] with the theme's flick projection when null.
  final SheetDetents? detents;

  /// Where the sheet opens; the lower stop of adaptive detents, else the content's full height, when null.
  final SheetOffset? initialOffset;

  /// Observes and moves the sheet.
  final OnaSheetController? controller;

  /// How the sheet responds past its bounds and how it settles; clamped on the theme's spring when null.
  final SheetPhysics? physics;

  /// The surface colour; the theme's when null.
  final Color? backgroundColor;

  /// The radius of the top corners; the theme's when null.
  final double? cornerRadius;

  /// Replaces the themed surface entirely when set.
  final SheetDecoration? decoration;

  /// How the sheet and a scroll view inside it share a drag; on by default.
  ///
  /// By default it works as on iOS ([SheetScrollHandlingBehavior.onlyFromTop]): a drag that starts with the list at
  /// its top moves the sheet (up to its highest stop, then the list); a drag that starts with the list scrolled, and
  /// any flick's momentum, stay in the list, which bounces at its ends while the sheet stays put. With bouncing
  /// physics (iOS's default) the list rubber-bands at both ends.
  final SheetScrollConfiguration scrollConfiguration;

  /// How the sheet responds to drags.
  final SheetDragConfiguration dragConfiguration;

  /// When a drag puts the keyboard away; null keeps it up.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  /// Whether the content rises above the on-screen keyboard.
  final bool avoidsKeyboard;

  @override
  Widget build(BuildContext context) {
    final OnaBottomSheetTheme theme = OnaBottomSheetTheme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final SheetDetents effectiveDetents =
        detents ?? AdaptiveSheetDetents(flickProjection: theme.motion.flickProjection);
    final SheetOffset effectiveInitialOffset =
        initialOffset ??
        switch (effectiveDetents) {
          final AdaptiveSheetDetents adaptive => adaptive.rest,
          _ => const SheetOffset(1),
        };

    Widget sheet = RawSheet(
      controller: controller,
      initialOffset: effectiveInitialOffset,
      detents: effectiveDetents,
      physics: physics ?? ClampingSheetPhysics(spring: theme.motion.settle),
      scrollConfiguration: scrollConfiguration,
      dragConfiguration: dragConfiguration,
      padding: avoidsKeyboard ? EdgeInsets.only(bottom: media.viewInsets.bottom) : EdgeInsets.zero,
      decoration:
          decoration ??
          BoxSheetDecoration(
            size: SheetSize.fit,
            decoration: ShapeDecoration(
              color: backgroundColor ?? theme.backgroundColor,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius ?? theme.cornerRadius)),
              ),
            ),
          ),
      child: child,
    );
    if (keyboardDismissBehavior case final SheetKeyboardDismissBehavior behavior) {
      sheet = SheetKeyboardDismissible(dismissBehavior: behavior, child: sheet);
    }
    // One slop for the sheet's own drag and every scroll view in it.
    return MediaQuery(
      data: media.copyWith(gestureSettings: DeviceGestureSettings(touchSlop: theme.touchSlop)),
      child: sheet,
    );
  }
}

/// The grabber at the top of a sheet: the place a thumb takes hold of it.
///
/// For screen readers it is an adjustable control: swiping up or down moves the sheet to its next stop, as
/// VoiceOver does with a native sheet's grabber.
class OnaSheetGrabber extends StatelessWidget {
  /// Creates a grabber in the theme's colour and size, unless [color] or [size] are given.
  const OnaSheetGrabber({super.key, this.color, this.size, this.semanticsLabel = 'Sheet grabber'});

  /// The grabber's colour; the theme's when null.
  final Color? color;

  /// The grabber's size; the theme's when null.
  final Size? size;

  /// What screen readers call the grabber.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final OnaBottomSheetTheme theme = OnaBottomSheetTheme.of(context);
    final SheetModel? model = SheetModelOwner.of(context);
    final Size effectiveSize = size ?? theme.grabberSize;
    return Semantics(
      label: semanticsLabel,
      onIncrease: model == null ? null : () => _step(model, up: true),
      onDecrease: model == null ? null : () => _step(model, up: false),
      child: SizedBox.fromSize(
        size: effectiveSize,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: color ?? theme.grabberColor, shape: const StadiumBorder()),
        ),
      ),
    );
  }

  /// Moves the sheet to its next stop up or down: the stop a very fast release would pick.
  static void _step(SheetModel model, {required bool up}) {
    if (!model.hasMetrics) return;
    final SheetOffset target = model.detents.getSnapOffset(model, model.offset, up ? 1e6 : -1e6);
    model.animateTo(target, curve: Curves.easeOutCubic);
  }
}
