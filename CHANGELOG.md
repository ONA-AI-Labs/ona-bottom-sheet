# Changelog

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
