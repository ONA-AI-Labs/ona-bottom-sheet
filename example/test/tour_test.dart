import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';
import 'package:ona_bottom_sheet_example/main.dart';

/// Every demo in the tour opens its sheet and closes again.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('each modal demo opens and closes', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());

    for (final String demo in <String>['Long list', 'Confirm', 'Form', 'Custom theme']) {
      await tester.tap(find.text(demo));
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsOneWidget, reason: demo);
      await tester.tapAt(const Offset(195, 40));
      await settle(tester);
      expect(find.byType(OnaBottomSheet), findsNothing, reason: demo);
    }
  });

  testWidgets('the always-on sheet sits on its screen', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Always on'));
    await settle(tester);
    expect(find.byType(OnaBottomSheet), findsOneWidget);
    expect(find.text('Tap the map'), findsOneWidget);
  });
}
