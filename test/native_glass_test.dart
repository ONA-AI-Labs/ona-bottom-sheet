import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';
import 'package:ona_bottom_sheet/src/widgets/glass_surface.dart';
import 'package:ona_bottom_sheet/src/widgets/native_glass_surface.dart';

/// On iOS 26 and later a glass sheet is Apple's Liquid Glass, drawn by iOS behind the Flutter content. iOS is mocked
/// here: these tests check what Flutter asks of it, and when.
void main() {
  const Size phone = Size(390, 844);

  /// The views iOS was asked to create, by id: their type and creation parameters.
  late Map<int, ({String type, Object? params})> created;

  /// The ids of the views iOS was asked to dispose.
  late List<int> disposed;

  /// Every `update` iOS was sent, in order.
  late List<Map<Object?, Object?>> updates;

  setUp(() {
    nativeGlassSupportOverride = true;
    created = <int, ({String type, Object? params})>{};
    disposed = <int>[];
    updates = <Map<Object?, Object?>>[];
  });

  tearDown(() => nativeGlassSupportOverride = null);

  /// Stands in for iOS: records platform view calls and answers each view's own channel.
  void mockIos(WidgetTester tester) {
    final TestDefaultBinaryMessenger messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
      switch (call.method) {
        case 'create':
          final Map<Object?, Object?> args = call.arguments as Map<Object?, Object?>;
          final int id = args['id']! as int;
          final Uint8List? params = args['params'] as Uint8List?;
          created[id] = (
            type: args['viewType']! as String,
            params: params == null ? null : const StandardMessageCodec().decodeMessage(ByteData.sublistView(params)),
          );
          final MethodChannel channel = MethodChannel('ona_bottom_sheet/glass_surface_$id');
          messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
            expect(call.method, 'update');
            updates.add(call.arguments as Map<Object?, Object?>);
            return null;
          });
          addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        case 'dispose':
          disposed.add(call.arguments as int);
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform_views, null));
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> open(
    WidgetTester tester, {
    OnaBottomSheetTheme theme = OnaBottomSheetTheme.light,
    OnaSheetStyle style = const OnaSheetStyle.glass(),
    bool highContrast = false,
    Widget? probe,
  }) async {
    tester.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(highContrast: highContrast);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    mockIos(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[theme.copyWith(style: style)]),
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
                              for (int i = 0; i < 40; i++)
                                SizedBox(
                                  height: 50,
                                  child: TextButton(onPressed: () {}, child: Text('Row $i')),
                                ),
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

  RenderSolidVeil veil(WidgetTester tester) => tester.allRenderObjects.whereType<RenderSolidVeil>().single;

  testWidgets("a glass sheet is Apple's glass, the sheet's size, behind its content", (tester) async {
    await open(tester);
    expect(find.byType(GlassSheetSurface), findsNothing);
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty, reason: 'iOS draws the glass, not Flutter');
    expect(created, hasLength(1));
    final ({String type, Object? params}) view = created.values.single;
    expect(view.type, 'ona_bottom_sheet/glass_surface');
    expect(view.params, <String, Object>{'cornerRadius': 38.0, 'dark': false, 'hidden': false});

    final Rect glass = tester.getRect(find.byType(UiKitView));
    final Rect sheet = tester.getRect(find.byType(NativeGlassSheetSurface));
    expect(glass, sheet);
    expect(veil(tester).solidity, 0);
    expect(find.byType(NativeGlassSheetSurface), isNot(paints..rsuperellipse()), reason: 'no veil at half');

    // A tap goes to the content, never to the native view.
    await tester.tap(find.text('Row 0'));
    expect(find.descendant(of: find.byType(IgnorePointer), matching: find.byType(UiKitView)), findsOneWidget);
  });

  testWidgets('rising to full fades in the veil and stops the glass; going back to half brings it back', (
    tester,
  ) async {
    await open(tester);
    await tester.drag(find.text('Title'), const Offset(0, -600));
    await settle(tester);
    expect(veil(tester).solidity, 1);
    expect(
      find.byType(NativeGlassSheetSurface),
      paints..rsuperellipse(color: OnaBottomSheetTheme.light.backgroundColor),
      reason: 'an opaque veil in the sheet colour',
    );
    expect(updates, <Map<Object?, Object?>>[
      <String, Object>{'cornerRadius': 38.0, 'dark': false, 'hidden': true},
    ], reason: 'one message for the whole drag');

    await tester.drag(find.text('Title'), const Offset(0, 250));
    await settle(tester);
    expect(veil(tester).solidity, 0);
    expect(updates.last['hidden'], false);
    expect(updates, hasLength(2));
  });

  testWidgets('halfway up, glass shows through a part-opaque veil', (tester) async {
    await open(tester);
    final TestGesture finger = await tester.startGesture(tester.getCenter(find.text('Title')));
    await finger.moveBy(const Offset(0, -20));
    await finger.moveBy(const Offset(0, -300));
    await tester.pump();
    expect(veil(tester).solidity, inExclusiveRange(0, 1));
    expect(updates, isEmpty, reason: 'the glass is still drawn');
    await finger.up();
    await settle(tester);
  });

  testWidgets('a drag never rebuilds the sheet', (tester) async {
    int builds = 0;
    await open(
      tester,
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
    expect(builds, before);
  });

  testWidgets('a dark theme gets the dark glass', (tester) async {
    await open(tester, theme: OnaBottomSheetTheme.dark);
    expect((created.values.single.params! as Map<Object?, Object?>)['dark'], true);
  });

  testWidgets('a theme change while open restyles the glass in place', (tester) async {
    tester.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    mockIos(tester);
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
    await tester.pump();
    theme.value = OnaBottomSheetTheme.dark.copyWith(style: const OnaSheetStyle.glass(), cornerRadius: 20);
    // MaterialApp animates a theme change over 200 ms.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(created, hasLength(1), reason: 'updated, not recreated');
    expect(updates.last, <String, Object>{'cornerRadius': 20.0, 'dark': true, 'hidden': false});
  });

  testWidgets('closing the sheet disposes its glass', (tester) async {
    await open(tester);
    await tester.drag(find.text('Title'), const Offset(0, 700));
    await settle(tester);
    expect(find.byType(NativeGlassSheetSurface), findsNothing);
    expect(disposed, created.keys.toList());
  });

  testWidgets('with high contrast on, or the solid style, there is no glass at all', (tester) async {
    await open(tester, highContrast: true);
    expect(find.byType(UiKitView), findsNothing);
    expect(created, isEmpty);
  });

  testWidgets('before iOS 26, the glass is drawn by Flutter', (tester) async {
    nativeGlassSupportOverride = false;
    await open(tester);
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(GlassSheetSurface), findsOneWidget);
  });

  test('reads the major version out of an iOS version string', () {
    expect(iosMajorVersion('Version 26.0.1 (Build 23A355)'), 26);
    expect(iosMajorVersion('18.2'), 18);
    expect(iosMajorVersion('unknown'), 0);
  });
}
