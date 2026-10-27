import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// The logical size of the test view (flutter_test's default surface).
const Size testScreenSize = Size(800, 600);

/// Runs every test in this package with leak tracking on (an object the sheet creates and does not dispose fails
/// the test that leaked it) and with missed taps fatal (a tap that lands on nothing never passes by luck).
FutureOr<void> testExecutable(FutureOr<void> Function() testMain) {
  WidgetController.hitTestWarningShouldBeFatal = true;
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnored(createdByTestHelpers: true);
  return testMain();
}
