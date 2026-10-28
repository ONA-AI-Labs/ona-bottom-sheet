import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';
import 'package:ona_bottom_sheet/src/widgets/glass_surface.dart';

/// The liquid glass style: a blurred, tinted pane that turns solid at full, never rebuilt by a drag.
void main() {
  const Size phone = Size(390, 844);

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> open(
    WidgetTester tester, {
    OnaSheetStyle style = const OnaSheetStyle.glass(),
    int rows = 40,
    bool highContrast = false,
    Widget? probe,
  }) async {
    tester.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(highContrast: highContrast);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[OnaBottomSheetTheme.light.copyWith(style: style)]),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => unawaited(
                  showOnaBottomSheet<void>(
                    context: context,
                    builder: (_) => OnaBottomSheet(
                      child: OnaSheetScaffold(
                        header: const SizedBox(height: 50, child: Center(child: Text('Title'))),
                        body: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              ?probe,
                              for (int i = 0; i < rows; i++) SizedBox(height: 50, child: Text('Row $i')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  Iterable<BackdropFilterLayer> backdrops(WidgetTester tester) => tester.layers.whereType<BackdropFilterLayer>();

  testWidgets('at half the page shows through a blurred pane; at full it is solid and nothing is blurred', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(GlassSheetSurface), findsOneWidget);
    expect(backdrops(tester), hasLength(1), reason: 'one blur, for the whole sheet');
    final RenderGlassSheetSurface surface = tester.renderObject(find.byType(GlassSheetSurface));
    expect(surface.solidity, 0);
    expect(surface, paints..rsuperellipse(), reason: 'glass has its rim');

    await tester.drag(find.text('Title'), const Offset(0, -600));
    await settle(tester);
    expect(surface.solidity, 1);
    expect(backdrops(tester), isEmpty, reason: 'a solid pane blurs nothing');
    expect(surface, isNot(paints..rsuperellipse()), reason: 'and has no glass rim');

    await tester.drag(find.text('Title'), const Offset(0, 250));
    await settle(tester);
    expect(surface.solidity, 0);
    expect(backdrops(tester), hasLength(1));
  });

  testWidgets('halfway up, the pane is part glass, part solid', (tester) async {
    await open(tester);
    final RenderGlassSheetSurface surface = tester.renderObject(find.byType(GlassSheetSurface));
    final TestGesture finger = await tester.startGesture(tester.getCenter(find.text('Title')));
    await finger.moveBy(const Offset(0, -20));
    await finger.moveBy(const Offset(0, -300));
    await tester.pump();
    expect(surface.solidity, inExclusiveRange(0, 1));
    await finger.up();
    await settle(tester);
  });

  testWidgets('with solidAtFull off, the full sheet stays glass', (tester) async {
    await open(tester, style: const OnaSheetStyle.glass(solidAtFull: false));
    await tester.drag(find.text('Title'), const Offset(0, -600));
    await settle(tester);
    expect(backdrops(tester), hasLength(1));
  });

  testWidgets('a tint colours the pane at half; at full the pane is the theme background', (tester) async {
    const Color tint = Color(0xFFADBFD3);
    await open(tester, style: const OnaSheetStyle.glass(tint: tint));
    final Finder surface = find.byType(GlassSheetSurface);
    expect(surface, paints..rect(color: tint.withValues(alpha: 0.62)), reason: 'the tint, at tintOpacity');

    await tester.drag(find.text('Title'), const Offset(0, -600));
    await settle(tester);
    expect(surface, paints..rect(color: OnaBottomSheetTheme.light.backgroundColor));
  });

  testWidgets('a sheet with one stop stays glass', (tester) async {
    await open(tester, rows: 3);
    final RenderGlassSheetSurface surface = tester.renderObject(find.byType(GlassSheetSurface));
    expect(surface.solidity, 0);
    expect(backdrops(tester), hasLength(1));
  });

  testWidgets('with high contrast on, a glass sheet is drawn solid', (tester) async {
    await open(tester, highContrast: true);
    expect(find.byType(GlassSheetSurface), findsNothing);
    expect(backdrops(tester), isEmpty);
  });

  testWidgets('the solid style draws an opaque card and no blur', (tester) async {
    await open(tester, style: OnaSheetStyle.solid);
    expect(find.byType(GlassSheetSurface), findsNothing);
    expect(backdrops(tester), isEmpty);
  });

  for (final OnaSheetStyle style in <OnaSheetStyle>[OnaSheetStyle.solid, const OnaSheetStyle.glass()]) {
    testWidgets('a drag never rebuilds the sheet (${style.runtimeType})', (tester) async {
      int builds = 0;
      await open(
        tester,
        style: style,
        probe: Builder(
          builder: (BuildContext context) {
            builds++;
            return const SizedBox(height: 1);
          },
        ),
      );
      final int before = builds;
      await tester.drag(find.text('Title'), const Offset(0, -600));
      await settle(tester);
      await tester.drag(find.text('Title'), const Offset(0, 250));
      await settle(tester);
      expect(builds, before, reason: 'position reaches render objects only');
    });
  }

  testWidgets('a theme change while a glass sheet is open restyles it in place', (tester) async {
    tester.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ValueNotifier<OnaBottomSheetTheme> theme = ValueNotifier<OnaBottomSheetTheme>(
      OnaBottomSheetTheme.light.copyWith(style: const OnaSheetStyle.glass()),
    );
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<OnaBottomSheetTheme>(
        valueListenable: theme,
        builder: (BuildContext context, OnaBottomSheetTheme value, Widget? child) => MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[value]),
          home: OnaSheetViewport(
            child: OnaBottomSheet(
              child: OnaSheetScaffold(body: Container(height: 200, color: const Color(0x00000000))),
            ),
          ),
        ),
      ),
    );
    final RenderGlassSheetSurface surface = tester.renderObject(find.byType(GlassSheetSurface));
    expect(backdrops(tester), hasLength(1));

    theme.value = OnaBottomSheetTheme.dark.copyWith(
      style: const OnaSheetStyle.glass(blur: 12, saturation: 1.2),
      cornerRadius: 20,
    );
    // MaterialApp animates a theme change over 200 ms.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.renderObject(find.byType(GlassSheetSurface)), same(surface), reason: 'updated, not replaced');
    expect(backdrops(tester), hasLength(1));
    expect(find.byType(GlassSheetSurface), paints..rsuperellipse(), reason: 'the rim, at the new radius');

    theme.value = OnaBottomSheetTheme.dark;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GlassSheetSurface), findsNothing, reason: 'back to solid');
    expect(backdrops(tester), isEmpty);
  });

  test('styles compare by value, copy, and carry through the theme', () {
    const GlassSheetStyle glass = GlassSheetStyle();
    expect(glass, const OnaSheetStyle.glass());
    expect(glass.hashCode, const GlassSheetStyle().hashCode);
    expect(glass.copyWith(), glass);
    expect(glass.copyWith(blur: 12).blur, 12);
    expect(glass, isNot(glass.copyWith(solidAtFull: false)));
    expect(glass, isNot(glass.copyWith(tint: const Color(0xFFADBFD3))));
    expect(OnaSheetStyle.solid, const SolidSheetStyle());
    expect(OnaSheetStyle.solid.hashCode, const SolidSheetStyle().hashCode);
    expect(OnaSheetStyle.solid, isNot(glass));

    final OnaBottomSheetTheme themed = OnaBottomSheetTheme.light.copyWith(style: glass);
    expect(themed.style, glass);
    expect(OnaBottomSheetTheme.light.style, OnaSheetStyle.solid);
    expect(themed, isNot(OnaBottomSheetTheme.light));
    expect(OnaBottomSheetTheme.light.lerp(themed, 0.75).style, glass);
    expect(OnaBottomSheetTheme.light.lerp(themed, 0.25).style, OnaSheetStyle.solid);
  });
}
