# Changelog

## 0.4.0

- `GlassSheetStyle.tint`: a colour mixed into the glass. On iOS 26 and later it is Apple's own glass tint
  (`UIGlassEffect.tintColor`), sent to iOS only when it changes; the Flutter pane lays it over the blur at
  `tintOpacity`. A full sheet still turns solid in the theme's background.

## 0.3.2

- Apple's Liquid Glass is back, exactly as in 0.3.0: on iOS 26 and later a glass sheet is Apple's `UIGlassEffect`,
  elsewhere the Flutter-drawn pane. The package is an iOS plugin again.

## 0.3.1

- Apple's Liquid Glass removed: glass was the Flutter-drawn pane on every platform, as in 0.2.1.

## 0.3.0

- Glass is Apple's Liquid Glass (`UIGlassEffect`) on iOS 26 and later, drawn by iOS behind the sheet's content:
  - in the sheet's shape, light or dark to match the theme
  - a veil in the sheet's colour fades in over it toward the highest stop; at the top, iOS stops drawing it
  - iOS is messaged only when the shape, brightness or visibility changes, never per frame
- Elsewhere, and before iOS 26, the Flutter-drawn glass stays as it was.
- The package is now a Flutter plugin on iOS (a small Swift view, CocoaPods and Swift Package Manager). It adds no
  dependencies.

## 0.2.1

- Glass: the light rim fades out with the glass as the pane turns solid, so a full sheet has no highlight line
  down its top edges.

## 0.2.0

- `OnaSheetStyle`: `solid` (the default) or liquid `glass`, on `OnaBottomSheetTheme.style` or `OnaBottomSheet.style`.
  - Glass blurs and colour-lifts the page behind, tints it with the theme's background, and catches the top edge with
    a light rim.
  - It turns opaque at the highest stop and stops blurring there.
  - It falls back to solid under high contrast.
- Glass is drawn by one render object with one clipped backdrop filter. It builds the filter once and reuses its
  layers, so a drag repaints and never rebuilds.
- The example has a Liquid glass switch.

## 0.1.2

- Scrolling inside a sheet works as on iOS, now `OnaBottomSheet`'s default (`SheetScrollHandlingBehavior.onlyFromTop`):
  - A drag that starts with the list at its top moves the sheet; a drag that starts with the list scrolled stays in the
    list, which rubber-bands at its top instead of pulling the sheet down.
  - A flick's momentum never moves a sheet resting at a stop: the list carries on and bounces at its top or end.
- `onlyFromTop` decides "at the top" within a device pixel, so a list that has just bounced back hands the next pull
  down to the sheet.

## 0.1.1

- A list in an `OnaBottomSheet` now bounces at its ends (with bouncing physics, iOS's default) while the sheet stays
  put: the overscroll the clamped sheet cannot take goes to the list. Pulling the list down at its top still lowers
  or closes the sheet first.

## 0.1.0

First release.

- `showOnaBottomSheet`, `OnaBottomSheetRoute` and `OnaBottomSheetPage`: modal sheets that dim the page without
  moving it, stop at the safe area, close on a tap, a swipe, the back gesture or a screen reader's escape, and can
  be held open by a `PopScope`.
- `OnaBottomSheet`: adaptive stops (whole when the content fits, else half and full), a non-bouncy 0.35 s spring,
  flick projection, clamping at the top, a shared drag with the list inside, and keyboard awareness.
- `OnaSheetViewport`: always-on sheets on a screen without a route.
- `OnaSheetScaffold` with a header, body and footer; the footer stays in view at partial heights, over a fade.
- `OnaSheetGrabber`, adjustable by screen readers.
- `OnaBottomSheetTheme` and `OnaSheetMotion`: one `ThemeExtension` for colours, corners, grabber, dimming, slop and
  motion, with light and dark defaults.
- A drag follows the finger 1:1 once it has moved 10 pt, and a swipe closes the sheet at the speed of the finger.
- `RawSheet`, `SheetDetents`, `SheetOffset`, `SheetPhysics` and `OnaSheetController` for full control.
