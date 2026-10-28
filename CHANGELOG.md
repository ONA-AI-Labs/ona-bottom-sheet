# Changelog

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
