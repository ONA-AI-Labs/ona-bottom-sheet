import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import 'raw_sheet.dart';
import 'viewport.dart';

/// Defines how the [OnaSheetScaffold.footer] of [OnaSheetScaffold]
/// should be displayed in response to the bottom inset caused by system UI.
///
/// {@template SheetContentScaffoldFooterVisibility.ignoreBottomInset}
/// If [ignoreBottomInset] is `true`, the footer will move up
/// along with the [OnaSheetScaffold.body] when the `bottom` value of
/// [MediaQueryData.viewInsets] increases due to system UI elements,
/// such as the on-screen keyboard.
///
/// If `false`, the footer will be partially or entirely hidden,
/// depending on the `bottom` value of [MediaQueryData.viewInsets].
/// For example, if the `bottom` value of [MediaQueryData.viewInsets]
/// is half the height of the footer, only half of the footer
/// will remain visible. The default value is `false`.
/// {@endtemplate}
sealed class FooterVisibility {
  /// Creates an object that defines the visibility of
  /// the [OnaSheetScaffold.footer] within a [OnaSheetScaffold].
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  const FooterVisibility({this.ignoreBottomInset = false});

  /// {@macro NaturalFooterVisibility}
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  const factory FooterVisibility.natural({bool ignoreBottomInset}) = NaturalFooterVisibility;

  /// {@macro AlwaysVisibleFooterVisibility}
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  /// With [scrimColor] set, the footer stands on a fade of that colour while content runs on below it.
  const factory FooterVisibility.always({bool ignoreBottomInset, Color? scrimColor}) = AlwaysVisibleFooterVisibility;

  /// {@macro ControlledFooterVisibility}
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  const factory FooterVisibility.controlled({bool ignoreBottomInset, required Animation<double> animation}) =
      ControlledFooterVisibility;

  /// {@macro ConditionalFooterVisibility}
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  const factory FooterVisibility.conditional({
    bool ignoreBottomInset,
    required bool Function(SheetMetrics) isVisible,
    Duration duration,
    Curve curve,
  }) = ConditionalFooterVisibility;

  /// Whether the footer should be visible when the `bottom`
  /// of [MediaQueryData.viewInsets] is increased by system UI elements,
  /// such as the onscreen keyboard.
  ///
  /// {@macro SheetContentScaffoldFooterVisibility.ignoreBottomInset}
  ///
  /// Even if this property is `true`, the footer may be hidden
  /// depending on the [FooterVisibility] type. For example,
  /// when using [ConditionalFooterVisibility], the footer is
  /// always hidden if the [ConditionalFooterVisibility.isVisible]
  /// callback returns `false`.
  final bool ignoreBottomInset;
}

/// {@template NaturalFooterVisibility}
/// The footer is displayed naturally, based on the sheet's offset.
/// {@endtemplate}
class NaturalFooterVisibility extends FooterVisibility {
  /// Creates a visibility that leaves the footer where the layout puts it.
  const NaturalFooterVisibility({super.ignoreBottomInset});
}

/// {@template AlwaysVisibleFooterVisibility}
/// The footer is always visible regardless of the sheet's offset.
///
/// Note that, contrary to the name, the bar will be hidden when the
/// keyboard is open and [ignoreBottomInset] is `false`.
/// {@endtemplate}
class AlwaysVisibleFooterVisibility extends FooterVisibility {
  /// Creates a visibility that keeps the footer in view.
  const AlwaysVisibleFooterVisibility({super.ignoreBottomInset, this.scrimColor});

  /// When set, the footer stands on a fade of this colour (usually the sheet's own) while the body runs on below
  /// it, as it does when a long sheet rests partway up; with all the content in view, nothing is drawn.
  final Color? scrimColor;
}

/// {@template ControlledFooterVisibility}
/// The visibility of the footer is controlled by the [animation].
///
/// The value of the [animation] must be between 0 and 1, where 0 means
/// the footer is completely invisible and 1 means it's completely visible.
///
/// Note that, the [OnaSheetScaffold.extendBodyBehindFooter]
/// property must be `true` when using this visibility type,
/// otherwise an error will be thrown.
/// {@endtemplate}
class ControlledFooterVisibility extends FooterVisibility {
  /// Creates a visibility that [animation] drives.
  const ControlledFooterVisibility({super.ignoreBottomInset, required this.animation});

  /// How visible the footer is, 0 (hidden) to 1 (shown).
  final Animation<double> animation;
}

/// {@template ConditionalFooterVisibility}
/// The visibility of the footer is controlled by the [isVisible] callback.
///
/// The [isVisible] callback is called whenever the sheet offset changes.
/// Returning `true` keeps the footer visible regardless of the offset,
/// and `false` hides it with an animation which has the [duration] and
/// [curve].
///
/// Note that, the [OnaSheetScaffold.extendBodyBehindFooter]
/// property must be `true` when using this visibility type,
/// otherwise an error will be thrown.
/// {@endtemplate}
class ConditionalFooterVisibility extends FooterVisibility {
  /// Creates a visibility that shows the footer while [isVisible] holds.
  const ConditionalFooterVisibility({
    super.ignoreBottomInset,
    required this.isVisible,
    this.initialIsVisible = true,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
  });

  /// Whether the footer should show for the sheet's current metrics.
  final bool Function(SheetMetrics) isVisible;

  /// Whether the footer shows before the sheet is laid out.
  final bool initialIsVisible;

  /// How long the footer takes to show or hide.
  final Duration duration;

  /// The curve the footer shows and hides on.
  final Curve curve;
}

/// The basic layout of the content in a [RawSheet].
///
/// Similar to [Scaffold], this widget provides the slots for the [header],
/// [footer], and [body]. Unlike [Scaffold], however, this widget
/// sizes its height to fit the [body] height. The hights of [header]
/// and [footer] are also taken into account depending on
/// [extendBodyBehindHeader], [extendBodyBehindFooter], and
/// [footerVisibility] (see each property for more details).
class OnaSheetScaffold extends StatelessWidget {
  /// Creates the basic layout of the content in a sheet.
  const OnaSheetScaffold({
    super.key,
    this.extendBodyBehindFooter = false,
    this.extendBodyBehindHeader = false,
    this.footerVisibility = const FooterVisibility.natural(),
    this.backgroundColor,
    this.header,
    this.footer,
    required this.body,
  });

  /// Whether to extend the body behind the [footer].
  ///
  /// If `true`:
  /// * the height of the [body] is extended to include the height of the
  ///   [footer].
  /// * the bottom of the [body] is aligned with the **bottom** of the
  ///   [footer].
  /// * the [body] is displayed behind the [footer].
  /// * the height of the [footer] is exposed to the [body] as `bottom`
  ///   of [MediaQueryData.padding].
  ///
  /// If `false`:
  /// * the height of the [body] does not include the height of the [footer].
  /// * the bottom of the [body] is aligned with the **top** of the [footer].
  ///
  /// Defaults to `false` and has no effect if [footer] is not specified.
  final bool extendBodyBehindFooter;

  /// Whether to extend the body behind the [header].
  ///
  /// If `true`:
  /// * the height of the [body] is extended to include the height of the
  ///   [header].
  /// * the top of the [body] is aligned with the **top** of the [header].
  /// * the [body] is displayed behind the [header].
  /// * the height of the [header] is exposed to the [body] as `top`
  ///   of [MediaQueryData.padding].
  ///
  /// If `false`:
  /// * the height of the [body] does not include the height of the [header].
  /// * the top of the [body] is aligned with the **bottom** of the [header].
  ///
  /// Defaults to `false` and has no effect if [header] is not specified.
  final bool extendBodyBehindHeader;

  /// Determines the visibility of the [footer].
  ///
  /// If [FooterVisibility.ignoreBottomInset] is `false`
  /// and [extendBodyBehindFooter] is `true`, and the [footer] is
  /// partially or entirely hidden, the height of the [body] is reduced by
  /// the amount of the invisible part of the [footer].
  ///
  /// Defaults to [FooterVisibility.natural].
  final FooterVisibility footerVisibility;

  /// Color of the [Material] widget that underlies the entire scaffold.
  ///
  /// Defaults to [ThemeData.scaffoldBackgroundColor].
  final Color? backgroundColor;

  /// Widget that is displayed at the top of the scaffold.
  final Widget? header;

  /// Widget that is displayed at the bottom of the scaffold.
  final Widget? footer;

  /// Widget that is displayed in the center of the scaffold.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    var effectiveHeader = header;
    if (effectiveHeader case PreferredSizeWidget(:final preferredSize)) {
      final topViewPadding = MediaQuery.viewPaddingOf(context).top;
      effectiveHeader = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: preferredSize.height + topViewPadding),
        child: header,
      );
    }

    var effectiveFooter = footer;
    if (footer != null) {
      if (footer case PreferredSizeWidget(:final preferredSize)) {
        final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
        effectiveFooter = ConstrainedBox(
          constraints: BoxConstraints(maxHeight: preferredSize.height + bottomViewPadding),
          child: footer,
        );
      }
      switch (footerVisibility) {
        case NaturalFooterVisibility():
          // No additional widget is needed.
          break;

        case AlwaysVisibleFooterVisibility(:final scrimColor):
          effectiveFooter = _AlwaysVisibleFooterVisibility(
            child: scrimColor == null ? effectiveFooter : _FooterScrim(color: scrimColor, child: effectiveFooter),
          );

        case ControlledFooterVisibility(:final animation):
          assert(
            extendBodyBehindFooter,
            'FooterVisibility.controlled must be used with '
            'OnaSheetScaffold.extendBodyBehindFooter set to true.',
          );
          effectiveFooter = _ControlledFooterVisibility(visibility: animation, child: effectiveFooter);

        case final ConditionalFooterVisibility it:
          assert(
            extendBodyBehindFooter,
            'FooterVisibility.conditional must be used with '
            'OnaSheetScaffold.extendBodyBehindFooter set to true.',
          );
          effectiveFooter = _ConditionalFooterVisibility(
            getIsVisible: it.isVisible,
            initialIsVisible: it.initialIsVisible,
            duration: it.duration,
            curve: it.curve,
            child: effectiveFooter,
          );
      }
    }

    return Material(
      color: effectiveBackgroundColor,
      child: _ScaffoldLayout(
        extendBodyBehindHeader: extendBodyBehindHeader,
        extendBodyBehindFooter: extendBodyBehindFooter,
        ignoreBottomInset: footerVisibility.ignoreBottomInset,
        header: effectiveHeader,
        footer: effectiveFooter,
        body: _ScaffoldBodyContainer(child: body),
      ),
    );
  }
}

enum _ScaffoldSlot { body, header, footer }

class _ScaffoldLayout extends SlottedMultiChildRenderObjectWidget<_ScaffoldSlot, RenderBox> {
  const _ScaffoldLayout({
    required this.extendBodyBehindHeader,
    required this.extendBodyBehindFooter,
    required this.ignoreBottomInset,
    required this.header,
    required this.footer,
    required this.body,
  });

  final bool extendBodyBehindHeader;
  final bool extendBodyBehindFooter;
  final bool ignoreBottomInset;
  final Widget? header;
  final Widget? footer;
  final Widget body;

  @override
  Iterable<_ScaffoldSlot> get slots => _ScaffoldSlot.values;

  @override
  Widget? childForSlot(_ScaffoldSlot slot) {
    switch (slot) {
      case _ScaffoldSlot.header:
        return header;
      case _ScaffoldSlot.footer:
        return footer;
      case _ScaffoldSlot.body:
        return body;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox> createRenderObject(BuildContext context) {
    final viewportContext = OnaSheetViewportState.of(context)?.context;
    return _RenderScaffoldLayout(
      extendBodyBehindHeader: extendBodyBehindHeader,
      extendBodyBehindFooter: extendBodyBehindFooter,
      ignoreBottomInset: ignoreBottomInset,
      sheetLayoutSpec: SheetMediaQuery.layoutSpecOf(context),
      viewportViewInsets: viewportContext != null ? MediaQuery.viewInsetsOf(viewportContext) : EdgeInsets.zero,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox> renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    final viewportContext = OnaSheetViewportState.of(context)?.context;
    (renderObject as _RenderScaffoldLayout)
      ..extendBodyBehindHeader = extendBodyBehindHeader
      ..extendBodyBehindFooter = extendBodyBehindFooter
      ..ignoreBottomInset = ignoreBottomInset
      ..sheetLayoutSpec = SheetMediaQuery.layoutSpecOf(context)
      ..viewportViewInsets = viewportContext != null ? MediaQuery.viewInsetsOf(viewportContext) : EdgeInsets.zero;
  }
}

class _RenderScaffoldLayout extends RenderBox with SlottedContainerRenderObjectMixin<_ScaffoldSlot, RenderBox> {
  _RenderScaffoldLayout({
    required bool extendBodyBehindHeader,
    required bool extendBodyBehindFooter,
    required bool ignoreBottomInset,
    required SheetLayoutSpec sheetLayoutSpec,
    required EdgeInsets viewportViewInsets,
  }) : _extendBodyBehindHeader = extendBodyBehindHeader,
       _extendBodyBehindFooter = extendBodyBehindFooter,
       _ignoreBottomInset = ignoreBottomInset,
       _sheetLayoutSpec = sheetLayoutSpec,
       _viewportViewInsets = viewportViewInsets;

  bool get extendBodyBehindHeader => _extendBodyBehindHeader;
  bool _extendBodyBehindHeader;
  set extendBodyBehindHeader(bool value) {
    if (value != _extendBodyBehindHeader) {
      _extendBodyBehindHeader = value;
      markNeedsLayout();
    }
  }

  bool get extendBodyBehindFooter => _extendBodyBehindFooter;
  bool _extendBodyBehindFooter;
  set extendBodyBehindFooter(bool value) {
    if (value != _extendBodyBehindFooter) {
      _extendBodyBehindFooter = value;
      markNeedsLayout();
    }
  }

  bool get ignoreBottomInset => _ignoreBottomInset;
  bool _ignoreBottomInset;
  set ignoreBottomInset(bool value) {
    if (value != _ignoreBottomInset) {
      _ignoreBottomInset = value;
      markNeedsLayout();
    }
  }

  SheetLayoutSpec get sheetLayoutSpec => _sheetLayoutSpec;
  SheetLayoutSpec _sheetLayoutSpec;
  set sheetLayoutSpec(SheetLayoutSpec value) {
    if (value != _sheetLayoutSpec) {
      _sheetLayoutSpec = value;
      markNeedsLayout();
    }
  }

  EdgeInsets get viewportViewInsets => _viewportViewInsets;
  EdgeInsets _viewportViewInsets;
  set viewportViewInsets(EdgeInsets value) {
    if (value != _viewportViewInsets) {
      _viewportViewInsets = value;
      markNeedsLayout();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'OnaSheetScaffold does not support returning intrinsic dimensions.\n'
          'Calculating the dry layout would require running the layout callback '
          'speculatively, which might mutate the live render object tree.',
        );
      }
      return true;
    }());

    return true;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry layout would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return Size.zero;
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry baseline would require running the layout callback speculatively, '
            'which might mutate the live render object tree.',
      ),
    );
    return null;
  }

  @override
  void performLayout() {
    Size layoutChild(_ScaffoldSlot slot, BoxConstraints constraints) {
      return switch (childForSlot(slot)) {
        null => Size.zero,
        final child => (child..layout(constraints, parentUsesSize: true)).size,
      };
    }

    void positionChild(_ScaffoldSlot slot, Offset offset) {
      if (childForSlot(slot) case final child?) {
        (child.parentData! as BoxParentData).offset = offset;
      }
    }

    final childConstraints = BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );

    // Layout the bars.
    final headerHeight = layoutChild(_ScaffoldSlot.header, childConstraints).height;
    final footerHeight = layoutChild(_ScaffoldSlot.footer, childConstraints).height;

    // Calculate the visible height of the footer.
    final double visibleFooterHeight;
    if (ignoreBottomInset) {
      visibleFooterHeight = footerHeight;
    } else {
      visibleFooterHeight = max(footerHeight - viewportViewInsets.bottom, 0);
    }

    // Layout the body.
    final bodyMargin = EdgeInsets.only(
      top: extendBodyBehindHeader ? 0 : headerHeight,
      bottom: extendBodyBehindFooter ? 0 : visibleFooterHeight,
    );
    final bodyMaxHeight = max(childConstraints.maxHeight - bodyMargin.vertical, 0.0);
    final bodyHeight = layoutChild(
      _ScaffoldSlot.body,
      _ScaffoldBodyConstraints(
        headerOverlap: extendBodyBehindHeader ? headerHeight : 0,
        footerOverlap: extendBodyBehindFooter ? visibleFooterHeight : 0,
        minWidth: childConstraints.minWidth,
        maxWidth: childConstraints.maxWidth,
        minHeight: constraints.isTight ? bodyMaxHeight : 0,
        maxHeight: bodyMaxHeight,
      ),
    ).height;

    // Position the header.
    positionChild(_ScaffoldSlot.header, Offset.zero);
    // Position the body
    positionChild(_ScaffoldSlot.body, Offset(0, bodyMargin.top));
    // Position the footer.
    final bodyBottom = bodyMargin.top + bodyHeight;
    final footerTop = extendBodyBehindFooter ? bodyBottom - visibleFooterHeight : bodyBottom;
    positionChild(_ScaffoldSlot.footer, Offset(0, footerTop));

    // Finally, lay out the scaffold itself.
    final contentHeight = bodyMargin.vertical + bodyHeight;
    size = constraints.constrain(Size(constraints.maxWidth, contentHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintChild(_ScaffoldSlot slot) {
      if (childForSlot(slot) case final child?) {
        final parentData = child.parentData! as BoxParentData;
        context.paintChild(child, offset + parentData.offset);
      }
    }

    // Paints the children in the reverse of hit test order.
    paintChild(_ScaffoldSlot.body);
    paintChild(_ScaffoldSlot.header);
    paintChild(_ScaffoldSlot.footer);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool hitTestChild(_ScaffoldSlot slot) {
      if (childForSlot(slot) case final child?) {
        final parentData = child.parentData! as BoxParentData;
        return result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) => child.hitTest(result, position: transformed),
        );
      }
      return false;
    }

    return hitTestChild(_ScaffoldSlot.footer) || hitTestChild(_ScaffoldSlot.header) || hitTestChild(_ScaffoldSlot.body);
  }
}

class _ScaffoldBodyConstraints extends BoxConstraints {
  const _ScaffoldBodyConstraints({
    required this.headerOverlap,
    required this.footerOverlap,
    super.minWidth,
    super.maxWidth,
    super.minHeight,
    super.maxHeight,
  });

  final double headerOverlap;
  final double footerOverlap;
}

class _ScaffoldBodyContainer extends StatelessWidget {
  const _ScaffoldBodyContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyConstraints = constraints as _ScaffoldBodyConstraints;
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            padding: mediaQuery.padding.copyWith(
              top: bodyConstraints.headerOverlap,
              bottom: bodyConstraints.footerOverlap,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

abstract class _RenderFooterVisibility extends RenderTransform {
  _RenderFooterVisibility({required SheetModelView model, required SheetLayoutListenable layoutNotifier})
    : _model = model,
      _layoutNotifier = layoutNotifier,
      super(transform: Matrix4.zero(), transformHitTests: true) {
    _model.addListener(invalidateTranslationValues);
    _layoutNotifier.addListener(invalidateTranslationValues);
  }

  SheetModelView _model;

  // ignore: avoid_setters_without_getters
  set model(SheetModelView value) {
    if (_model != value) {
      _model.removeListener(invalidateTranslationValues);
      _model = value..addListener(invalidateTranslationValues);
      invalidateTranslationValues();
    }
  }

  // While we don't read the value from this notifier,
  // we need to listen to it to update the transform matrix
  // and reflect the latest layout.
  SheetLayoutListenable _layoutNotifier;

  // ignore: avoid_setters_without_getters
  set layoutNotifier(SheetLayoutListenable value) {
    if (_layoutNotifier != value) {
      _layoutNotifier.removeListener(invalidateTranslationValues);
      _layoutNotifier = value..addListener(invalidateTranslationValues);
    }
  }

  @override
  void dispose() {
    _model.removeListener(invalidateTranslationValues);
    _layoutNotifier.removeListener(invalidateTranslationValues);
    super.dispose();
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  Size? _footerSize;

  @override
  void performLayout() {
    super.performLayout();
    _footerSize = size;
    invalidateTranslationValues();
  }

  void invalidateTranslationValues() {
    final footerSize = _footerSize;
    if (footerSize != null && _model.hasMetrics) {
      // This translation ensures that the bar is fully visible even when
      // the sheet's content is partially or fully outside of the viewport.
      final baseDeltaY = (_model.viewportSize.height - _model.contentBaseline - _model.contentRect.bottom).clamp(
        // Prevent the bar from being moved up
        // when the content is fully outside of the viewport.
        min(0.0, footerSize.height - _model.contentSize.height),
        // We don't need to move the bar up
        // when the content is fully visible within the viewport.
        0.0,
      );
      final visibility = computeVisibility(_model, footerSize);
      assert(0 <= visibility && visibility <= 1);
      final invisibleHeight = footerSize.height * (1 - visibility);
      // Apply additional translation that is controlled by computeVisibility().
      final deltaY = baseDeltaY + invisibleHeight;
      transform = Matrix4.translationValues(0, deltaY, 0);
    }
  }

  double computeVisibility(SheetMetrics sheetMetrics, Size footerSize);
}

class _AlwaysVisibleFooterVisibility extends SingleChildRenderObjectWidget {
  const _AlwaysVisibleFooterVisibility({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAlwaysVisibleFooterVisibility(
      model: SheetModelOwner.of(context)!,
      layoutNotifier: SheetMediaQuery.layoutNotifierOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderAlwaysVisibleFooterVisibility)
      ..model = SheetModelOwner.of(context)!
      ..layoutNotifier = SheetMediaQuery.layoutNotifierOf(context);
  }
}

class _RenderAlwaysVisibleFooterVisibility extends _RenderFooterVisibility {
  _RenderAlwaysVisibleFooterVisibility({required super.model, required super.layoutNotifier});

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size footerSize) {
    return 1;
  }
}

class _ControlledFooterVisibility extends SingleChildRenderObjectWidget {
  const _ControlledFooterVisibility({required this.visibility, required super.child});

  final Animation<double> visibility;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderControlledFooterVisibility(
      model: SheetModelOwner.of(context)!,
      layoutNotifier: SheetMediaQuery.layoutNotifierOf(context),
      visibility: visibility,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderControlledFooterVisibility)
      ..model = SheetModelOwner.of(context)!
      ..layoutNotifier = SheetMediaQuery.layoutNotifierOf(context)
      ..visibility = visibility;
  }
}

class _RenderControlledFooterVisibility extends _RenderFooterVisibility {
  _RenderControlledFooterVisibility({
    required super.model,
    required super.layoutNotifier,
    required Animation<double> visibility,
  }) : _visibility = visibility {
    _visibility.addListener(invalidateTranslationValues);
  }

  Animation<double> _visibility;

  // ignore: avoid_setters_without_getters
  set visibility(Animation<double> value) {
    if (_visibility != value) {
      _visibility.removeListener(invalidateTranslationValues);
      _visibility = value..addListener(markNeedsLayout);
    }
  }

  @override
  void dispose() {
    _visibility.removeListener(invalidateTranslationValues);
    super.dispose();
  }

  @override
  double computeVisibility(SheetMetrics sheetMetrics, Size footerSize) {
    return _visibility.value;
  }
}

class _ConditionalFooterVisibility extends StatefulWidget {
  const _ConditionalFooterVisibility({
    required this.getIsVisible,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.initialIsVisible = false,
    required this.child,
  });

  final bool initialIsVisible;
  final bool Function(SheetMetrics) getIsVisible;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  @override
  State<_ConditionalFooterVisibility> createState() => _ConditionalFooterVisibilityState();
}

class _ConditionalFooterVisibilityState extends State<_ConditionalFooterVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _curveAnimation;
  SheetModelView? _model;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.initialIsVisible ? 1.0 : 0.0,
      duration: widget.duration,
    );

    _curveAnimation = _createCurvedAnimation();
  }

  @override
  void dispose() {
    _model?.removeListener(_didSheetMetricsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ConditionalFooterVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.curve != oldWidget.curve) {
      _curveAnimation = _createCurvedAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = SheetModelOwner.of(context)!;
    if (_model != model) {
      _model?.removeListener(_didSheetMetricsChanged);
      _model = model..addListener(_didSheetMetricsChanged);
      _didSheetMetricsChanged();
    }
  }

  Animation<double> _createCurvedAnimation() {
    return _controller.drive(CurveTween(curve: widget.curve));
  }

  void _didSheetMetricsChanged() {
    final isVisible = _model!.hasMetrics && widget.getIsVisible(_model!);

    if (isVisible) {
      if (_controller.status != AnimationStatus.forward) {
        _controller.forward();
      }
    } else {
      if (_controller.status != AnimationStatus.reverse) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ControlledFooterVisibility(visibility: _curveAnimation, child: widget.child);
  }
}

/// Paints a fade of [color] behind the footer while the sheet's content runs on below the viewport (under the
/// footer), reaching full strength over the first 24 pixels of overlap. Paint only: the sheet moving repaints this
/// box and rebuilds nothing.
class _FooterScrim extends SingleChildRenderObjectWidget {
  const _FooterScrim({required this.color, required super.child});

  final Color color;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFooterScrim(model: SheetModelOwner.of(context)!, color: color);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderFooterScrim)
      ..model = SheetModelOwner.of(context)!
      ..color = color;
  }
}

class _RenderFooterScrim extends RenderProxyBox {
  _RenderFooterScrim({required SheetModel model, required Color color}) : _model = model, _color = color {
    _model.addListener(markNeedsPaint);
  }

  SheetModel _model;
  set model(SheetModel value) {
    if (identical(value, _model)) return;
    _model.removeListener(markNeedsPaint);
    _model = value..addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_model.hasMetrics) {
      final double under = _model.contentRect.bottom - (_model.viewportSize.height - _model.contentBaseline);
      final double strength = (under / 24).clamp(0.0, 1.0);
      if (strength > 0) {
        final Rect rect = offset & size;
        final Color solid = _color.withValues(alpha: _color.a * strength);
        context.canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.35],
              colors: <Color>[solid.withValues(alpha: 0), solid],
            ).createShader(rect),
        );
      }
    }
    super.paint(context, offset);
  }

  @override
  void dispose() {
    _model.removeListener(markNeedsPaint);
    super.dispose();
  }
}
