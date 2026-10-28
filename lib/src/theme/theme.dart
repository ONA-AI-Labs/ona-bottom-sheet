/// @docImport '../modal/route.dart';
/// @docImport '../widgets/bottom_sheet.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../physics/physics.dart';
import 'style.dart';

/// How an Ona sheet moves: how it settles on a stop, how it comes in and goes away, and how a flick picks its stop.
///
/// The defaults follow Apple's guidance for fluid interfaces: a non-bouncy spring for settling, a fast-start curve
/// for presenting, a quicker exit, and a flick that carries the sheet about half a second's travel.
@immutable
class OnaSheetMotion {
  /// Creates a motion description; every value has an Ona default.
  const OnaSheetMotion({
    this.settle = kOnaSheetSpring,
    this.presentDuration = const Duration(milliseconds: 500),
    this.presentCurve = const Cubic(0.32, 0.72, 0, 1),
    this.dismissDuration = const Duration(milliseconds: 300),
    this.flickProjection = 0.499,
  }) : assert(flickProjection >= 0);

  /// The spring the sheet settles on after a drag, or when it is moved to a stop.
  final SpringDescription settle;

  /// How long a modal sheet takes to come in.
  final Duration presentDuration;

  /// The curve a modal sheet comes in on; it goes away along the same curve, reversed.
  final Curve presentCurve;

  /// How long a modal sheet takes to go away when it is closed without a swipe.
  final Duration dismissDuration;

  /// How far ahead, in seconds, a release's speed is projected to choose the stop the sheet settles on.
  ///
  /// The default, 0.499 s, is the travel a scroll view's normal deceleration (0.998 per millisecond) gives a flick:
  /// a slow release settles back, a flick carries on. Zero chooses the nearest stop, whatever the speed.
  final double flickProjection;

  /// A copy with the given values replaced.
  OnaSheetMotion copyWith({
    SpringDescription? settle,
    Duration? presentDuration,
    Curve? presentCurve,
    Duration? dismissDuration,
    double? flickProjection,
  }) {
    return OnaSheetMotion(
      settle: settle ?? this.settle,
      presentDuration: presentDuration ?? this.presentDuration,
      presentCurve: presentCurve ?? this.presentCurve,
      dismissDuration: dismissDuration ?? this.dismissDuration,
      flickProjection: flickProjection ?? this.flickProjection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OnaSheetMotion &&
      other.settle.mass == settle.mass &&
      other.settle.stiffness == settle.stiffness &&
      other.settle.damping == settle.damping &&
      other.presentDuration == presentDuration &&
      other.presentCurve == presentCurve &&
      other.dismissDuration == dismissDuration &&
      other.flickProjection == flickProjection;

  @override
  int get hashCode => Object.hash(
    settle.mass,
    settle.stiffness,
    settle.damping,
    presentDuration,
    presentCurve,
    dismissDuration,
    flickProjection,
  );
}

/// The look and motion of every Ona sheet in an app.
///
/// Add it to [ThemeData.extensions] to restyle every [OnaBottomSheet] and [showOnaBottomSheet] at once; without it,
/// [OnaBottomSheetTheme.light] or [OnaBottomSheetTheme.dark] applies, following the ambient [ThemeData.brightness].
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(extensions: [OnaBottomSheetTheme.light.copyWith(cornerRadius: 24)]),
/// );
/// ```
@immutable
class OnaBottomSheetTheme extends ThemeExtension<OnaBottomSheetTheme> {
  /// Creates a sheet theme.
  const OnaBottomSheetTheme({
    required this.backgroundColor,
    required this.barrierColor,
    required this.grabberColor,
    this.cornerRadius = 38,
    this.grabberSize = const Size(36, 5),
    this.touchSlop = 10,
    this.motion = const OnaSheetMotion(),
    this.style = OnaSheetStyle.solid,
  }) : assert(cornerRadius >= 0),
       assert(touchSlop > 0);

  /// Ona's light sheet: a white card over a page dimmed by 28%.
  static const OnaBottomSheetTheme light = OnaBottomSheetTheme(
    backgroundColor: Color(0xFFFFFFFF),
    barrierColor: Color(0x47000000),
    grabberColor: Color(0x4D3C3C43),
  );

  /// Ona's dark sheet: an elevated graphite card over a page dimmed by 50%.
  static const OnaBottomSheetTheme dark = OnaBottomSheetTheme(
    backgroundColor: Color(0xFF1C1C1E),
    barrierColor: Color(0x80000000),
    grabberColor: Color(0x4DEBEBF5),
  );

  /// The theme in effect at [context]: the [ThemeData] extension if there is one, else the default for the
  /// ambient brightness.
  static OnaBottomSheetTheme of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<OnaBottomSheetTheme>() ?? (theme.brightness == Brightness.dark ? dark : light);
  }

  /// The sheet's surface.
  final Color backgroundColor;

  /// The colour laid over the page behind a modal sheet.
  final Color barrierColor;

  /// The grabber's colour.
  final Color grabberColor;

  /// The radius of the sheet's top corners.
  final double cornerRadius;

  /// The grabber's width and height.
  final Size grabberSize;

  /// How far a finger must move, in logical pixels, before a drag on the sheet begins.
  ///
  /// 10 is the distance iOS waits for; Flutter's own default is 18. Once begun, the sheet follows the finger
  /// exactly, the distance included.
  final double touchSlop;

  /// How the sheet moves.
  final OnaSheetMotion motion;

  /// What the sheet is made of: [OnaSheetStyle.solid] (the default) or [OnaSheetStyle.glass], tinted with
  /// [backgroundColor].
  final OnaSheetStyle style;

  @override
  OnaBottomSheetTheme copyWith({
    Color? backgroundColor,
    Color? barrierColor,
    Color? grabberColor,
    double? cornerRadius,
    Size? grabberSize,
    double? touchSlop,
    OnaSheetMotion? motion,
    OnaSheetStyle? style,
  }) {
    return OnaBottomSheetTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barrierColor: barrierColor ?? this.barrierColor,
      grabberColor: grabberColor ?? this.grabberColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      grabberSize: grabberSize ?? this.grabberSize,
      touchSlop: touchSlop ?? this.touchSlop,
      motion: motion ?? this.motion,
      style: style ?? this.style,
    );
  }

  @override
  OnaBottomSheetTheme lerp(covariant OnaBottomSheetTheme? other, double t) {
    if (other == null) return this;
    return OnaBottomSheetTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      grabberColor: Color.lerp(grabberColor, other.grabberColor, t)!,
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t)!,
      grabberSize: Size.lerp(grabberSize, other.grabberSize, t)!,
      touchSlop: lerpDouble(touchSlop, other.touchSlop, t)!,
      motion: t < 0.5 ? motion : other.motion,
      style: t < 0.5 ? style : other.style,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OnaBottomSheetTheme &&
      other.backgroundColor == backgroundColor &&
      other.barrierColor == barrierColor &&
      other.grabberColor == grabberColor &&
      other.cornerRadius == cornerRadius &&
      other.grabberSize == grabberSize &&
      other.touchSlop == touchSlop &&
      other.motion == motion &&
      other.style == style;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, barrierColor, grabberColor, cornerRadius, grabberSize, touchSlop, motion, style);
}
