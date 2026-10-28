/// @docImport '../widgets/bottom_sheet.dart';
/// @docImport 'theme.dart';
library;

import 'package:flutter/foundation.dart';

/// What an Ona sheet's surface is made of: [solid], or liquid [OnaSheetStyle.glass].
///
/// Set it for every sheet on [OnaBottomSheetTheme.style], or for one on [OnaBottomSheet.style].
@immutable
sealed class OnaSheetStyle {
  const OnaSheetStyle();

  /// Liquid glass: Apple's own on iOS 26 and later, elsewhere a frosted pane Flutter draws; see [GlassSheetStyle].
  const factory OnaSheetStyle.glass({
    double blur,
    double saturation,
    double tintOpacity,
    double rimOpacity,
    bool solidAtFull,
  }) = GlassSheetStyle;

  /// An opaque surface in the theme's background colour. Costs nothing to draw: the default.
  static const OnaSheetStyle solid = SolidSheetStyle();
}

/// An opaque surface; see [OnaSheetStyle.solid].
final class SolidSheetStyle extends OnaSheetStyle {
  /// Creates the solid style.
  const SolidSheetStyle();

  @override
  bool operator ==(Object other) => other is SolidSheetStyle;

  @override
  int get hashCode => (SolidSheetStyle).hashCode;
}

/// A liquid glass surface.
///
/// On iOS 26 and later it is Apple's Liquid Glass (`UIGlassEffect`), drawn by iOS behind the sheet's content in the
/// sheet's shape, light or dark to match its colour; iOS is told about the sheet only when that shape, brightness or
/// visibility changes, never per frame.
///
/// Elsewhere, Flutter draws it: the page behind is blurred by [blur], its colours lifted by [saturation], and tinted
/// with the theme's background at [tintOpacity]; a light rim of [rimOpacity] catches the top edge. These four shape
/// this pane only. It is one backdrop filter clipped to the sheet's shape, the filter built once and every layer
/// reused, so a drag repaints and never rebuilds.
///
/// With [solidAtFull], as on iOS, the glass turns opaque as the sheet rises to its highest stop and is no longer
/// drawn once there, so a full sheet reads as a page and costs what a solid one does. A sheet with a single stop stays
/// glass. When the platform asks for high contrast, the sheet is drawn solid.
final class GlassSheetStyle extends OnaSheetStyle {
  /// Creates a glass style; every value has a tuned default.
  const GlassSheetStyle({
    this.blur = 24,
    this.saturation = 1.8,
    this.tintOpacity = 0.62,
    this.rimOpacity = 0.55,
    this.solidAtFull = true,
  }) : assert(blur >= 0),
       assert(saturation >= 0),
       assert(tintOpacity >= 0 && tintOpacity <= 1),
       assert(rimOpacity >= 0 && rimOpacity <= 1);

  /// The blur's sigma, in logical pixels.
  final double blur;

  /// How much the colours behind are lifted: 1 leaves them, more makes them richer, 0 makes them grey.
  final double saturation;

  /// How opaque the tint (the theme's background colour) laid over the blurred page is.
  final double tintOpacity;

  /// How bright the light rim along the top edge is.
  final double rimOpacity;

  /// Whether the pane turns opaque as the sheet reaches its highest stop, as iOS sheets do.
  final bool solidAtFull;

  /// A copy with the given values replaced.
  GlassSheetStyle copyWith({
    double? blur,
    double? saturation,
    double? tintOpacity,
    double? rimOpacity,
    bool? solidAtFull,
  }) {
    return GlassSheetStyle(
      blur: blur ?? this.blur,
      saturation: saturation ?? this.saturation,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      rimOpacity: rimOpacity ?? this.rimOpacity,
      solidAtFull: solidAtFull ?? this.solidAtFull,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassSheetStyle &&
      other.blur == blur &&
      other.saturation == saturation &&
      other.tintOpacity == tintOpacity &&
      other.rimOpacity == rimOpacity &&
      other.solidAtFull == solidAtFull;

  @override
  int get hashCode => Object.hash(blur, saturation, tintOpacity, rimOpacity, solidAtFull);
}
