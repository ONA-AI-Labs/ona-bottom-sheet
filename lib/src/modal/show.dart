/// @docImport '../widgets/bottom_sheet.dart';
library;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/viewport.dart';
import 'route.dart';

/// Shows the sheet [builder] returns over the current page, styled and timed by the [OnaBottomSheetTheme], and
/// completes with the value it is popped with.
///
/// [builder] should return a sheet, usually an [OnaBottomSheet]. The page behind is dimmed, never moved; a full
/// sheet stops at the safe area's top. A tap outside, a swipe down, the back gesture and a screen reader's escape
/// close it, unless [isDismissible] is false, in which case it still drags and springs back. A [PopScope] or
/// [SheetPopScope] inside the sheet can refuse a close while work is in flight.
///
/// When the platform asks for animations to be removed ([MediaQueryData.disableAnimations]), it appears and goes
/// away at once; drags still follow the finger.
///
/// ```dart
/// final bool? confirmed = await showOnaBottomSheet<bool>(
///   context: context,
///   builder: (context) => OnaBottomSheet(child: ConfirmDelete()),
/// );
/// ```
Future<T?> showOnaBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  String? semanticsLabel,
  String? barrierLabel,
}) {
  final OnaBottomSheetTheme theme = OnaBottomSheetTheme.of(context);
  final bool still = MediaQuery.disableAnimationsOf(context);
  final MaterialLocalizations? words = Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    OnaBottomSheetRoute<T>(
      settings: routeSettings,
      builder: builder,
      barrierColor: theme.barrierColor,
      barrierDismissible: isDismissible,
      swipeDismissible: isDismissible,
      barrierLabel: barrierLabel ?? words?.modalBarrierDismissLabel,
      semanticsLabel: semanticsLabel,
      transitionDuration: still ? Duration.zero : theme.motion.presentDuration,
      dismissDuration: still ? Duration.zero : theme.motion.dismissDuration,
      transitionCurve: theme.motion.presentCurve,
      viewportBuilder: (BuildContext context, Widget child) => OnaSheetViewport(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: child,
      ),
    ),
  );
}
