# ona-bottom-sheet: agent map

Ona's Flutter bottom sheet package (`ona_bottom_sheet`). It is used by the Ona app (`../ona-mobile-app`) and written to
be published for other developers. The repo is private and `publish_to: none` for now; it is consumed by git tag.

## Commands

- `flutter pub get`
- `dart format -l 120 --set-exit-if-changed lib test example/lib example/test`
- `flutter analyze` (zero issues; strict casts, inference and raw types; every public member documented)
- `flutter test` (355+ tests; leak tracking and fatal missed taps are on for every test, see `test/flutter_test_config.dart`)
- `flutter test --coverage`: keep `lib/src` at 90% of lines or above
- `cd example && flutter test`: the tour's smoke tests
- `dart run build_runner build --delete-conflicting-outputs`: regenerates `test/src/stubbing.mocks.dart` after an
  API change to a mocked type
- `cd example && flutter run --dart-define=ONA_TOUR=true`: walks the demos by itself (README screenshots)
- `cd example && flutter run --profile -t lib/bench.dart`: frame bench on a device

## Layout

- `lib/src/foundation/`: the position model, activities, controller, notifications, float comparison.
- `lib/src/physics/`: `SheetPhysics` (clamping, bouncing, `kOnaSheetSpring`) and `SheetDetents` (multi, single,
  stepless, adaptive; flick projection).
- `lib/src/gestures/`: the sheet's own drag (`DragStartBehavior.down`, slop from `MediaQuery`).
- `lib/src/scroll/`: the sheet-aware scroll controller and position (list and sheet share one drag).
- `lib/src/widgets/`: `RawSheet` (the neutral engine), `OnaBottomSheet` (themed), viewport, scaffold, grabber,
  decorations, keyboard.
- `lib/src/modal/`: the route, the page and `showOnaBottomSheet`.
- `lib/src/theme/`: `OnaBottomSheetTheme` and `OnaSheetMotion`.
- `ios/`: the plugin (CocoaPods `ona_bottom_sheet.podspec` and SPM `ona_bottom_sheet/Package.swift`). One Swift view,
  Apple's `UIGlassEffect`, behind a glass sheet on iOS 26+ (`lib/src/widgets/native_glass_surface.dart` creates it).

## Rules

- `RawSheet` keeps neutral defaults, because the engine tests rely on them. Ona's opinions live in
  `OnaBottomSheet`, `showOnaBottomSheet` and the theme.
- A drag must never rebuild widgets. Position changes reach render objects through listeners only (see
  `_FooterScrim`).
- Everything created is disposed. A leak fails the test suite.
- No third-party names anywhere except the one retained line in `LICENSE`.
- The native glass is messaged only when its shape, brightness or visibility changes, never per frame. The view
  type and channel names in Swift and Dart must match. Swift changes are checked by building the Ona app for the
  iOS 26 simulator and a device; unit tests mock iOS.
