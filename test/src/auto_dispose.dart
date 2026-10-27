import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Disposes [notifier] when the current test ends and returns it, so a test's own objects never show up as leaks.
T autoDispose<T extends ChangeNotifier>(T notifier) {
  addTearDown(notifier.dispose);
  return notifier;
}
