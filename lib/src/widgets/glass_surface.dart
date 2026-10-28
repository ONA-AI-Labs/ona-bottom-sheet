import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import '../theme/style.dart';

/// The liquid glass surface of a sheet: the page behind, blurred and colour-lifted, under a tint and a light rim,
/// clipped to the sheet's rounded top.
///
/// One render object does it all and keeps its layers from frame to frame. The sheet moving only repaints it, and
/// only when the opacity it derives from the sheet's position changes.
@internal
class GlassSheetSurface extends SingleChildRenderObjectWidget {
  /// Creates a glass surface around [child], the sheet.
  const GlassSheetSurface({
    super.key,
    required this.style,
    required this.color,
    required this.cornerRadius,
    required super.child,
  });

  /// How the glass is made.
  final GlassSheetStyle style;

  /// The tint, and the colour the pane turns when solid.
  final Color color;

  /// The radius of the top corners.
  final double cornerRadius;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGlassSheetSurface(
    model: SheetModelOwner.of(context),
    style: style,
    color: color,
    cornerRadius: cornerRadius,
  );

  @override
  void updateRenderObject(BuildContext context, RenderGlassSheetSurface renderObject) {
    renderObject
      ..model = SheetModelOwner.of(context)
      ..style = style
      ..color = color
      ..cornerRadius = cornerRadius;
  }
}

/// The render object behind [GlassSheetSurface].
@internal
class RenderGlassSheetSurface extends RenderProxyBox {
  /// Creates the glass surface's render object.
  RenderGlassSheetSurface({
    required SheetModel? model,
    required GlassSheetStyle style,
    required Color color,
    required double cornerRadius,
  }) : _model = model,
       _style = style,
       _color = color,
       _cornerRadius = cornerRadius {
    _model?.addListener(_onSheetMoved);
  }

  SheetModel? _model;
  set model(SheetModel? value) {
    if (identical(value, _model)) return;
    _model?.removeListener(_onSheetMoved);
    _model = value?..addListener(_onSheetMoved);
    markNeedsPaint();
  }

  GlassSheetStyle _style;
  set style(GlassSheetStyle value) {
    if (value == _style) return;
    _style = value;
    _filter = null;
    markNeedsPaint();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  double _cornerRadius;
  set cornerRadius(double value) {
    if (value == _cornerRadius) return;
    _cornerRadius = value;
    markNeedsPaint();
  }

  final LayerHandle<ClipRSuperellipseLayer> _clip = LayerHandle<ClipRSuperellipseLayer>();
  final LayerHandle<BackdropFilterLayer> _backdrop = LayerHandle<BackdropFilterLayer>();

  /// The blur and colour lift, built once per style.
  ui.ImageFilter? _filter;

  /// How solid the pane was when last painted, 0 (glass) to 1 (opaque).
  double _paintedSolidity = -1;

  /// How solid the pane is for the sheet's position: 0 up to halfway between its lowest and highest stop, rising
  /// smoothly to 1 at the highest. A sheet with one stop, or [GlassSheetStyle.solidAtFull] off, stays glass.
  @visibleForTesting
  double get solidity {
    final SheetModel? model = _model;
    if (!_style.solidAtFull || model == null || !model.hasMetrics) return 0;
    final double span = model.maxOffset - model.minOffset;
    if (span < 1) return 0;
    final double t = ((model.offset - model.minOffset) / span - 0.5) * 2;
    final double x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  void _onSheetMoved() {
    if (solidity != _paintedSolidity) markNeedsPaint();
  }

  // The backdrop filter and the clip are layers of their own.
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final double solid = solidity;
    _paintedSolidity = solid;
    final RSuperellipse shape = RSuperellipse.fromRectAndCorners(
      Offset.zero & size,
      topLeft: Radius.circular(_cornerRadius),
      topRight: Radius.circular(_cornerRadius),
    );
    _clip.layer = context.pushClipRSuperellipse(needsCompositing, offset, Offset.zero & size, shape, (
      PaintingContext context,
      Offset offset,
    ) {
      if (solid >= 1) {
        // Fully opaque: nothing behind shows, so nothing is blurred.
        _backdrop.layer = null;
        _paintPane(context, offset, 1);
      } else {
        final BackdropFilterLayer backdrop = _backdrop.layer ??= BackdropFilterLayer();
        backdrop.filter = _filter ??= _buildFilter();
        context.pushLayer(backdrop, (PaintingContext context, Offset offset) {
          _paintPane(context, offset, _style.tintOpacity + (1 - _style.tintOpacity) * solid);
        }, offset);
      }
    }, oldLayer: _clip.layer);
  }

  void _paintPane(PaintingContext context, Offset offset, double opacity) {
    final Rect rect = offset & size;
    final Canvas canvas = context.canvas;
    canvas.drawRect(rect, Paint()..color = _color.withValues(alpha: _color.a * opacity));
    if (_style.rimOpacity > 0) {
      // A light rim catching the top edge and corners, fading out a little way down the sides.
      final double fade = _cornerRadius + 24;
      final Rect rimArea = Rect.fromLTWH(rect.left, rect.top, rect.width, fade);
      final RSuperellipse edge = RSuperellipse.fromRectAndCorners(
        rect.deflate(0.25),
        topLeft: Radius.circular(_cornerRadius),
        topRight: Radius.circular(_cornerRadius),
      );
      canvas.drawRSuperellipse(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..shader = ui.Gradient.linear(rimArea.topCenter, rimArea.bottomCenter, <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: _style.rimOpacity),
            const Color(0x00FFFFFF),
          ]),
      );
    }
    final RenderBox? child = this.child;
    if (child != null) context.paintChild(child, offset);
  }

  ui.ImageFilter _buildFilter() {
    final double s = _style.saturation;
    // Saturation with Rec. 709 luminance weights, applied to the blurred page.
    const double r = 0.2126, g = 0.7152, b = 0.0722;
    final ui.ColorFilter lift = ui.ColorFilter.matrix(<double>[
      r + (1 - r) * s, g - g * s, b - b * s, 0, 0, //
      r - r * s, g + (1 - g) * s, b - b * s, 0, 0, //
      r - r * s, g - g * s, b + (1 - b) * s, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
    return ui.ImageFilter.compose(
      outer: lift,
      inner: ui.ImageFilter.blur(sigmaX: _style.blur, sigmaY: _style.blur, tileMode: TileMode.mirror),
    );
  }

  @override
  void dispose() {
    _model?.removeListener(_onSheetMoved);
    _clip.layer = null;
    _backdrop.layer = null;
    super.dispose();
  }
}
