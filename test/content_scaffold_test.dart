import 'package:flutter/material.dart';
import 'package:ona_bottom_sheet/src/foundation/activity.dart';
import 'package:ona_bottom_sheet/src/foundation/model.dart';
import 'package:ona_bottom_sheet/src/foundation/model_owner.dart';
import 'package:ona_bottom_sheet/src/gestures/gesture_proxy.dart';
import 'package:ona_bottom_sheet/src/physics/detents.dart';
import 'package:ona_bottom_sheet/src/physics/physics.dart';
import 'package:ona_bottom_sheet/src/widgets/scaffold.dart';
import 'package:ona_bottom_sheet/src/widgets/viewport.dart';

import 'flutter_test_config.dart';
import 'src/auto_dispose.dart';
import 'src/flutter_test_x.dart';
import 'src/test_stateful_widget.dart';

void main() {
  group('OnaSheetScaffold - Core Layout', () {
    ({Widget testWidget}) boilerplate({
      SheetLayoutSpec? parentLayoutSpec,
      EdgeInsets rootViewInsets = EdgeInsets.zero,
      EdgeInsets rootViewPadding = EdgeInsets.zero,
      required WidgetBuilder builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(viewInsets: rootViewInsets, viewPadding: rootViewPadding),
        child: SheetMediaQuery(
          layoutNotifier: autoDispose<ValueNotifier<SheetLayout?>>(ValueNotifier(null)),
          layoutSpec:
              parentLayoutSpec ??
              const SheetLayoutSpec(
                viewportSize: testScreenSize,
                viewportPadding: EdgeInsets.zero,
                contentMargin: EdgeInsets.zero,
              ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Builder(builder: builder),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('Body-only layout with tight box-constraints', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), testScreenSize);
      expect(tester.getSize(find.byKey(bodyKey)), testScreenSize);
    });

    testWidgets('Body-only layout with loose box-constraints', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              body: SizedBox(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), Size(testScreenSize.width, 200));
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Body with zero-height in loose box-constraints', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              body: SizedBox(key: bodyKey, height: 0),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 0),
      );
    });

    testWidgets('Header-Body layout with tight box-constraints', (tester) async {
      final headerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              header: Container(key: headerKey, height: 50),
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), testScreenSize);
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 50, testScreenSize.width, testScreenSize.height - 50),
      );
    });

    testWidgets('Header-Body layout with loose box-constraints', (tester) async {
      final headerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              header: Container(key: headerKey, height: 50),
              body: Container(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), Size(testScreenSize.width, 250));
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 50, testScreenSize.width, 200),
      );
    });

    testWidgets('Body-Footer layout with tight box-constraints', (tester) async {
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              footer: Container(key: footerKey, height: 50),
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), testScreenSize);
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height - 50),
      );
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, testScreenSize.height - 50, testScreenSize.width, 50),
      );
    });

    testWidgets('Body-Footer layout with loose box-constraints', (tester) async {
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              footer: Container(key: footerKey, height: 50),
              body: Container(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), Size(testScreenSize.width, 250));
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 200, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Header-Body-Footer layout with tight box-constraints', (tester) async {
      final headerKey = UniqueKey();
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              header: Container(key: headerKey, height: 50),
              footer: Container(key: footerKey, height: 50),
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), testScreenSize);
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, testScreenSize.height - 50, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 50, testScreenSize.width, testScreenSize.height - 100),
      );
    });

    testWidgets('Header-Body-Footer layout with loose box-constraints', (tester) async {
      final headerKey = UniqueKey();
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: OnaSheetScaffold(
              key: const Key('scaffold'),
              header: Container(key: headerKey, height: 50),
              footer: Container(key: footerKey, height: 50),
              body: Container(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byId('scaffold')), Size(testScreenSize.width, 300));
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 250, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 50, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind header', (tester) async {
      final headerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return OnaSheetScaffold(
            key: const Key('scaffold'),
            extendBodyBehindHeader: true,
            header: Container(key: headerKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind footer', (tester) async {
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return OnaSheetScaffold(
            key: const Key('scaffold'),
            extendBodyBehindFooter: true,
            footer: Container(key: footerKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind top and footers', (tester) async {
      final headerKey = UniqueKey();
      final footerKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return OnaSheetScaffold(
            key: const Key('scaffold'),
            extendBodyBehindHeader: true,
            extendBodyBehindFooter: true,
            header: Container(key: headerKey, height: 50),
            footer: Container(key: footerKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('When header has a preferred size', (tester) async {
      final headerKey = UniqueKey();
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(
          key: const Key('scaffold'),
          header: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(key: headerKey, height: double.infinity),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(headerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('PreferredSizeWidget header gets extra available height '
        'from viewPadding.top', (tester) async {
      final env = boilerplate(
        rootViewPadding: const EdgeInsets.only(top: 50),
        builder: (context) => OnaSheetScaffold(
          key: const Key('scaffold'),
          header: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(key: const Key('header'), height: double.infinity),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byId('header'), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 110),
      );
    });

    testWidgets('PreferredSizeWidget footer gets extra available height '
        'from viewPadding.bottom', (tester) async {
      final env = boilerplate(
        rootViewPadding: const EdgeInsets.only(bottom: 34),
        builder: (context) => OnaSheetScaffold(
          key: const Key('scaffold'),
          footer: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(key: const Key('footer'), height: double.infinity),
          ),
          body: Container(height: 200, key: const Key('body')),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byId('footer'), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 200, testScreenSize.width, 94),
      );
    });

    testWidgets('Top bar can be shorter than preferredSize + viewPadding.top', (tester) async {
      final env = boilerplate(
        rootViewPadding: const EdgeInsets.only(top: 50),
        builder: (context) => OnaSheetScaffold(
          key: const Key('scaffold'),
          header: PreferredSize(
            key: const Key('header'),
            preferredSize: const Size.fromHeight(60),
            child: Container(height: 60),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byId('header'), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('Bottom bar can be shorter than preferredSize + viewPadding.bottom', (tester) async {
      final env = boilerplate(
        rootViewPadding: const EdgeInsets.only(bottom: 34),
        builder: (context) => OnaSheetScaffold(
          key: const Key('scaffold'),
          footer: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(key: const Key('footer'), height: 60),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byId('footer'), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 200, testScreenSize.width, 60),
      );
    });

    testWidgets('When footer has a preferred size', (tester) async {
      final footerKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return OnaSheetScaffold(
            key: const Key('scaffold'),
            footer: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(key: footerKey, height: double.infinity),
            ),
            body: Container(height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(footerKey), ancestor: find.byId('scaffold')),
        Rect.fromLTWH(0, 200, testScreenSize.width, 60),
      );
    });

    testWidgets('Background color fills entire area', (tester) async {
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(backgroundColor: Colors.purple, body: Container(height: 200)),
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.widget(find.byType(Material)), isA<Material>().having((m) => m.color, 'color', Colors.purple));
    });

    testWidgets('Applies background color from theme when not explicitly set', (tester) async {
      final env = boilerplate(
        builder: (context) => Theme(
          data: ThemeData(scaffoldBackgroundColor: Colors.purple),
          child: OnaSheetScaffold(body: Container(height: 200)),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.widget(find.byType(Material)), isA<Material>().having((m) => m.color, 'color', Colors.purple));
    });

    testWidgets('Exposes height of header as MediaQueryData.padding.top '
        'if extendBodyBehindHeader is true', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(
          header: Container(height: 50, color: Colors.blue),
          extendBodyBehindHeader: true,
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, const EdgeInsets.only(top: 50));
    });

    testWidgets('Removes MediaQueryData.padding.top if extendBodyBehindHeader is false', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(
          header: Container(height: 50, color: Colors.blue),
          extendBodyBehindHeader: false,
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, EdgeInsets.zero);
    });

    testWidgets('Exposes height of footer as MediaQueryData.padding.bottom '
        'if extendBodyBehindFooter is true', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(
          footer: Container(height: 50, color: Colors.blue),
          extendBodyBehindFooter: true,
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, const EdgeInsets.only(bottom: 50));
    });

    testWidgets('Removes MediaQueryData.padding.bottom '
        'if extendBodyBehindFooter is false', (tester) async {
      late EdgeInsets inheritedPadding;
      final env = boilerplate(
        builder: (context) => OnaSheetScaffold(
          extendBodyBehindFooter: false,
          footer: Container(height: 50, color: Colors.blue),
          body: Builder(
            builder: (context) {
              inheritedPadding = MediaQuery.of(context).padding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(inheritedPadding, EdgeInsets.zero);
    });

    testWidgets('Edge case: unstable layout should not violate parent constraints', (tester) async {
      // This test verifies that the scaffold does not violate its layout
      // constraints even when the layout is unstable due to a floating-point
      // precision issue. This can happen, for example, when the scaffold is
      // used as the sheet's content with footerVisibility set to
      // always(ignoreBottomInset: true), and the sheet is extending the
      // shrunk scaffold's height as the on-screen keyboard is disappearing.
      // The footer is also resized accordingly.
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(const Size.fromHeight(427.327643681333)),
            child: OnaSheetScaffold(
              footer: Container(color: Colors.white, width: double.infinity, height: 73.62690370255032),
              body: const SizedBox.expand(),
            ),
          );
        },
      );

      final errors = await tester.pumpWidgetAndCaptureErrors(env.testWidget);
      expect(
        errors,
        isEmpty,
        reason:
            '"_RenderScaffoldLayout does not meet its constraints." '
            'should not be thrown',
      );
    });
  });

  group('OnaSheetScaffold - footer visibility', () {
    ({
      Widget testWidget,
      ValueGetter<SheetModel> getModel,
      Rect Function(WidgetTesterX) getScaffoldRect,
      Rect Function(WidgetTesterX) getLocalBodyRect,
      Rect Function(WidgetTesterX) getLocalFooterRect,
      ValueSetter<double> updateKeyboardHeight,
    })
    boilerplate({
      required FooterVisibility visibility,
      EdgeInsets viewportPadding = EdgeInsets.zero,
      double initialKeyboardHeight = 0,
      bool extendBodyBehindFooter = true,
      Widget? body,
    }) {
      final modelOwnerKey = GlobalKey<SheetModelOwnerState>();
      final statefulKey = GlobalKey<TestStatefulWidgetState<double>>();

      _TestSheetModel buildTestModel(SheetContext context, _TestSheetModelConfig config) {
        return _TestSheetModel(context, config, initialOffset: const SheetOffset(1));
      }

      final testWidget = TestStatefulWidget(
        key: statefulKey,
        initialState: initialKeyboardHeight,
        builder: (context, keyboardHeight) {
          return MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
            child: OnaSheetViewport(
              child: SheetModelOwner(
                key: modelOwnerKey,
                factory: buildTestModel,
                config: const _TestSheetModelConfig(),
                child: BareSheet(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: SizedBox.expand(
                    child: Center(
                      child: OnaSheetScaffold(
                        key: const Key('scaffold'),
                        footerVisibility: visibility,
                        extendBodyBehindFooter: extendBodyBehindFooter,
                        body: body ?? Container(key: const Key('body'), color: Colors.white, height: double.infinity),
                        footer: Container(key: const Key('footer'), color: Colors.white, height: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      return (
        testWidget: testWidget,
        getModel: () => modelOwnerKey.currentState!.model,
        getLocalBodyRect: (tester) =>
            tester.getLocalRect(find.byKey(const Key('body')), ancestor: find.byKey(const Key('scaffold'))),
        getScaffoldRect: (tester) => tester.getLocalRect(find.byKey(const Key('scaffold'))),
        getLocalFooterRect: (tester) =>
            tester.getLocalRect(find.byKey(const Key('footer')), ancestor: find.byKey(const Key('scaffold'))),
        updateKeyboardHeight: (height) {
          statefulKey.currentState!.state = height;
        },
      );
    }

    testWidgets('natural - when keyboard is closed', (tester) async {
      final env = boilerplate(visibility: const FooterVisibility.natural());
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.getModel().offset = 700;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The offset should not affect the relative position of the bar',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The offset should not affect the relative position of the bar',
      );
    });

    testWidgets('natural - when keyboard is open, '
        'extendBodyBehindFooter is true, and ignoreBottomInset is false', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.natural(ignoreBottomInset: false),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });

    testWidgets('natural - when keyboard is open, '
        'extendBodyBehindFooter is false, and ignoreBottomInset is false', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.natural(ignoreBottomInset: false),
        extendBodyBehindFooter: false,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });

    testWidgets('natural - when keyboard is open and ignoreBottomInset is true', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.natural(ignoreBottomInset: true),
        initialKeyboardHeight: 0,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.updateKeyboardHeight(25);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 525, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 500, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );
    });

    testWidgets('always - when keyboard is closed', (tester) async {
      final env = boilerplate(visibility: const FooterVisibility.always());
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.getModel().offset = 700;
      await tester.pump();
      expect(env.getModel().rect.bottom, lessThan(600), reason: 'The bottom part of the sheet should be visible');
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason:
            'The offset should not affect the relative position of the bar '
            'when the bottom part of the sheet is within the viewport',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(
        env.getModel().visibleContentRect!.height,
        500,
        reason: 'The bottom part of the sheet is outside of the viewport',
      );
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 450, 800, 50),
        reason: 'The entire bar should be visible',
      );
    });

    testWidgets('always - when keyboard is open, '
        'extendBodyBehindFooter is true, and ignoreBottomInset is false', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.always(ignoreBottomInset: false),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });

    testWidgets('always - when keyboard is open, '
        'extendBodyBehindFooter is false, and ignoreBottomInset is false', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.always(ignoreBottomInset: false),
        extendBodyBehindFooter: false,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });

    testWidgets('always - when keyboard is open and ignoreBottomInset is true', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.always(ignoreBottomInset: true),
        initialKeyboardHeight: 0,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.updateKeyboardHeight(25);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 525, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 500, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 400, 800, 50),
        reason:
            'The bar should be visible even if '
            'the scaffold is partially outside of the viewport',
      );
    });

    testWidgets('always - when body has zero height', (tester) async {
      final env = boilerplate(
        visibility: const FooterVisibility.always(),
        extendBodyBehindFooter: false,
        body: const SizedBox.shrink(key: Key('body')),
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getScaffoldRect(tester).size, const Size(800, 50));
      expect(env.getLocalBodyRect(tester), const Rect.fromLTWH(0, 0, 800, 0));
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 0, 800, 50));
    });

    testWidgets('controlled - throws when extendBodyBehindFooter is false', (tester) async {
      final env = boilerplate(
        visibility: FooterVisibility.controlled(
          animation: Animation.fromValueListenable(autoDispose<ValueNotifier<double>>(ValueNotifier(1.0))),
        ),
        extendBodyBehindFooter: false,
      );

      final errors = await tester.pumpWidgetAndCaptureErrors(env.testWidget);
      expect(
        errors.first.exception,
        isAssertionError.having(
          (it) => it.message,
          'message',
          'FooterVisibility.controlled must be used with '
              'OnaSheetScaffold.extendBodyBehindFooter set to true.',
        ),
      );
    });

    testWidgets('controlled - when keyboard is closed', (tester) async {
      final visibilityNotifier = autoDispose(ValueNotifier(1.0));
      final env = boilerplate(
        visibility: FooterVisibility.controlled(animation: Animation.fromValueListenable(visibilityNotifier)),
        extendBodyBehindFooter: true,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      visibilityNotifier.value = 0.2;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 590, 800, 50),
        reason: 'Only 20% of the bar should be visible',
      );

      visibilityNotifier.value = 0.5;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 575, 800, 50),
        reason: 'Only half of the bar should be visible',
      );

      env.getModel().offset = 700;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 575, 800, 50),
        reason:
            'The bar should keep the specified visibility '
            'regardless of the offset',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 475, 800, 50),
        reason:
            'The bar should keep the specified visibility '
            'regardless of the offset',
      );
    });

    testWidgets('controlled - when keyboard is open and ignoreBottomInset is false', (tester) async {
      final visibilityNotifier = autoDispose(ValueNotifier(1.0));
      final env = boilerplate(
        visibility: FooterVisibility.controlled(
          ignoreBottomInset: false,
          animation: Animation.fromValueListenable(visibilityNotifier),
        ),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });
    testWidgets('controlled - when keyboard is open and ignoreBottomInset is true', (tester) async {
      final visibilityNotifier = autoDispose(ValueNotifier(1.0));
      final env = boilerplate(
        visibility: FooterVisibility.controlled(
          ignoreBottomInset: true,
          animation: Animation.fromValueListenable(visibilityNotifier),
        ),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 0,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.updateKeyboardHeight(25);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 525, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 500, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.getModel().offset = 500;
      await tester.pump();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 400, 800, 50),
        reason:
            'The bar should be visible even if '
            'the scaffold is partially outside of the viewport',
      );

      visibilityNotifier.value = 0.0;
      await tester.pump();
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 450, 800, 50),
        reason: 'The bar should be fully hidden',
      );
    });

    testWidgets('conditional - throws when extendBodyBehindFooter is false', (tester) async {
      final env = boilerplate(
        visibility: FooterVisibility.conditional(isVisible: (model) => true),
        extendBodyBehindFooter: false,
      );

      final errors = await tester.pumpWidgetAndCaptureErrors(env.testWidget);
      expect(
        errors.first.exception,
        isAssertionError.having(
          (it) => it.message,
          'message',
          'FooterVisibility.conditional must be used with '
              'OnaSheetScaffold.extendBodyBehindFooter set to true.',
        ),
      );
    });

    testWidgets('conditional - when keyboard is closed', (tester) async {
      final env = boilerplate(
        visibility: FooterVisibility.conditional(
          isVisible: (model) => model.offset >= 600,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
        extendBodyBehindFooter: true,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getLocalBodyRect(tester).height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.getModel().offset = 700;
      await tester.pump();
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50), reason: 'The bar should be visible');

      env.getModel().offset = 500;
      await tester.pump();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 450, 800, 50));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 462.5, 800, 50));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 475, 800, 50));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 487.5, 800, 50));

      await tester.pumpAndSettle();
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 500, 800, 50));
    });

    testWidgets('conditional - when keyboard is open and ignoreBottomInset is false', (tester) async {
      final env = boilerplate(
        visibility: FooterVisibility.conditional(
          isVisible: (model) => model.offset >= 600,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
          ignoreBottomInset: false,
        ),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 25,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(env.getLocalBodyRect(tester).height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'Half of the bar should be outside of the scaffold',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(env.getLocalBodyRect(tester).height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 550, 800, 50),
        reason: 'The entire bar should be outside of the scaffold',
      );
    });
    testWidgets('conditional - when keyboard is open and ignoreBottomInset is true', (tester) async {
      final env = boilerplate(
        visibility: FooterVisibility.conditional(
          isVisible: (model) => model.offset >= 600,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
          ignoreBottomInset: true,
        ),
        extendBodyBehindFooter: true,
        initialKeyboardHeight: 0,
      );
      await tester.pumpWidget(env.testWidget);

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 600);
      expect(env.getLocalFooterRect(tester), const Rect.fromLTWH(0, 550, 800, 50));

      env.updateKeyboardHeight(25);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 575);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 525, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.updateKeyboardHeight(50);
      await tester.pump();

      expect(env.getModel().offset, 600);
      expect(env.getScaffoldRect(tester).size.height, 550);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 500, 800, 50),
        reason: 'The keyboard height should not affect the layout of the bar',
      );

      env.getModel().offset = 500;
      await tester.pumpAndSettle();
      expect(env.getModel().visibleContentRect!.height, 500);
      expect(
        env.getLocalFooterRect(tester),
        const Rect.fromLTWH(0, 450, 800, 50),
        reason: 'The bar should be fully hidden',
      );
    });
  });

  group('OnaSheetScaffold - Hit-testing', () {
    ({Widget testWidget}) boilerplate({required Widget body, Widget? header, Widget? footer}) {
      final testWidget = MediaQuery(
        data: const MediaQueryData(),
        child: SheetMediaQuery(
          layoutNotifier: autoDispose<ValueNotifier<SheetLayout?>>(ValueNotifier(null)),
          layoutSpec: const SheetLayoutSpec(
            viewportSize: testScreenSize,
            viewportPadding: EdgeInsets.zero,
            contentMargin: EdgeInsets.zero,
          ),
          child: Center(
            child: SizedBox(
              width: 600,
              height: 400,
              child: OnaSheetScaffold(
                key: const Key('scaffold'),
                extendBodyBehindHeader: true,
                extendBodyBehindFooter: true,
                header: header,
                footer: footer,
                body: SizedBox.expand(child: body),
              ),
            ),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('When body-only', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(const Offset(100, 100), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(const Offset(699, 100), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(const Offset(100, 499), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(const Offset(699, 499), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(const Offset(99, 99), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(const Offset(700, 99), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(const Offset(99, 500), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(const Offset(700, 500), target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('When header exists', (tester) async {
      final bodyKey = UniqueKey();
      final headerKey = UniqueKey();
      final env = boilerplate(
        header: Container(key: headerKey, height: 50, color: Colors.blue),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(const Offset(100, 100), target: find.byKey(headerKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(const Offset(699, 100), target: find.byKey(headerKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(const Offset(100, 149), target: find.byKey(headerKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(const Offset(699, 149), target: find.byKey(headerKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(const Offset(99, 99), target: find.byKey(headerKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(const Offset(700, 99), target: find.byKey(headerKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(const Offset(99, 150), target: find.byKey(headerKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(const Offset(700, 150), target: find.byKey(headerKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('Top-bar should be prioritized over body', (tester) async {
      final bodyKey = UniqueKey();
      final headerKey = UniqueKey();
      final env = boilerplate(
        header: Container(key: headerKey, height: 50, color: Colors.blue),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      const centerOfHeader = Offset(400, 125);
      tester.hitTestAt(centerOfHeader, target: find.byKey(headerKey));
      expect(tester.takeException(), isNull);
      tester.hitTestAt(centerOfHeader, target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('When footer exists', (tester) async {
      final bodyKey = UniqueKey();
      final footerKey = UniqueKey();
      final env = boilerplate(
        footer: Container(key: footerKey, height: 50, color: Colors.red),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      // Top-left corner
      tester.hitTestAt(const Offset(100, 450), target: find.byKey(footerKey));
      expect(tester.takeException(), isNull);

      // Top-right corner
      tester.hitTestAt(const Offset(699, 450), target: find.byKey(footerKey));
      expect(tester.takeException(), isNull);

      // Bottom-left corner
      tester.hitTestAt(const Offset(100, 499), target: find.byKey(footerKey));
      expect(tester.takeException(), isNull);

      // Bottom-right corner
      tester.hitTestAt(const Offset(699, 499), target: find.byKey(footerKey));
      expect(tester.takeException(), isNull);

      // Out of top-left corner
      tester.hitTestAt(const Offset(99, 449), target: find.byKey(footerKey));
      expect(tester.takeException(), isNotNull);

      // Out of top-right corner
      tester.hitTestAt(const Offset(700, 449), target: find.byKey(footerKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-left corner
      tester.hitTestAt(const Offset(99, 500), target: find.byKey(footerKey));
      expect(tester.takeException(), isNotNull);

      // Out of bottom-right corner
      tester.hitTestAt(const Offset(700, 500), target: find.byKey(footerKey));
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('Bottom-bar should be prioritized over body', (tester) async {
      final bodyKey = UniqueKey();
      final footerKey = UniqueKey();
      final env = boilerplate(
        footer: Container(key: footerKey, height: 50, color: Colors.red),
        body: ColoredBox(key: bodyKey, color: Colors.white),
      );
      await tester.pumpWidget(env.testWidget);

      const centerOfFooter = Offset(400, 475);
      tester.hitTestAt(centerOfFooter, target: find.byKey(footerKey));
      expect(tester.takeException(), isNull);
      tester.hitTestAt(centerOfFooter, target: find.byKey(bodyKey));
      expect(tester.takeException(), isNotNull);
    });
  });

  group('OnaSheetScaffold - Semantics', () {
    testWidgets('Semantics child order matches paint order (body, header, footer)', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final containerKey = UniqueKey();
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SheetMediaQuery(
                layoutNotifier: autoDispose<ValueNotifier<SheetLayout?>>(ValueNotifier(null)),
                layoutSpec: const SheetLayoutSpec(
                  viewportSize: testScreenSize,
                  viewportPadding: EdgeInsets.zero,
                  contentMargin: EdgeInsets.zero,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: testScreenSize.width,
                    height: testScreenSize.height,
                    child: Semantics(
                      key: containerKey,
                      container: true,
                      explicitChildNodes: true,
                      child: OnaSheetScaffold(
                        extendBodyBehindHeader: true,
                        extendBodyBehindFooter: true,
                        header: Semantics(
                          container: true,
                          label: 'header',
                          child: const SizedBox(height: 50, width: double.infinity),
                        ),
                        footer: Semantics(
                          container: true,
                          label: 'footer',
                          child: const SizedBox(height: 50, width: double.infinity),
                        ),
                        body: Semantics(container: true, label: 'body', child: const SizedBox.expand()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final labels = <String>[];
        tester.getSemantics(find.byKey(containerKey)).visitChildren((child) {
          labels.add(child.label);
          return true;
        });
        expect(labels, ['body', 'header', 'footer']);
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}

class _TestSheetModelConfig extends SheetModelConfig {
  const _TestSheetModelConfig()
    : super(physics: const ClampingSheetPhysics(), detents: const SheetDetents.stepless(), gestureProxy: null);

  @override
  SheetModelConfig copyWith({SheetPhysics? physics, SheetDetents? detents, SheetGestureProxyMixin? gestureProxy}) {
    return const _TestSheetModelConfig();
  }
}

class _TestSheetModel extends SheetModel<_TestSheetModelConfig> {
  _TestSheetModel(super.context, super.config, {required SheetOffset initialOffset}) {
    beginActivity(InitialSheetActivity(preferredInitialOffset: initialOffset));
  }
}
