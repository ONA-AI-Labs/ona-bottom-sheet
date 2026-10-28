import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/model.dart';
import '../foundation/model_owner.dart';
import '../theme/style.dart';
import 'glass_surface.dart';

/// The platform view type of the iOS glass; keep in step with `OnaBottomSheetPlugin.swift`.
const String _viewType = 'ona_bottom_sheet/glass_surface';

/// Whether Apple's own Liquid Glass can be drawn here: on iOS 26 and later.
@internal
bool get nativeGlassSupported => nativeGlassSupportOverride ?? _nativeGlassSupported;

/// Forces [nativeGlassSupported] in tests; null asks the platform.
@visibleForTesting
bool? nativeGlassSupportOverride;

final bool _nativeGlassSupported = !kIsWeb && Platform.isIOS && iosMajorVersion(Platform.operatingSystemVersion) >= 26;

/// The major version in an iOS version string such as "Version 26.0.1 (Build 23A355)"; 0 if there is none.
@visibleForTesting
int iosMajorVersion(String version) => int.tryParse(RegExp(r'\d+').firstMatch(version)?[0] ?? '') ?? 0;

/// A glass sheet's surface on iOS 26 and later: Apple's Liquid Glass, drawn by iOS behind the sheet's content.
///
/// As the sheet rises to its highest stop, a veil in the sheet's colour fades in over the glass, as
/// [GlassSheetSurface] does; once the veil is opaque, iOS stops drawing the glass. iOS is only messaged when the
/// shape, the theme's brightness or that visibility changes, never per frame.
@internal
class NativeGlassSheetSurface extends StatefulWidget {
  /// Creates the native glass surface around [child], the sheet.
  const NativeGlassSheetSurface({
    super.key,
    required this.style,
    required this.color,
    required this.cornerRadius,
    required this.child,
  });

  /// When the sheet turns solid; the blur, saturation, tint and rim are Apple's.
  final GlassSheetStyle style;

  /// The colour the sheet turns when solid; its brightness picks the glass's light or dark look.
  final Color color;

  /// The radius of the top corners.
  final double cornerRadius;

  /// The sheet.
  final Widget child;

  @override
  State<NativeGlassSheetSurface> createState() => _NativeGlassSheetSurfaceState();
}

class _NativeGlassSheetSurfaceState extends State<NativeGlassSheetSurface> {
  SheetModel? _model;
  MethodChannel? _channel;

  // What iOS was last told, from the creation parameters on.
  late double _sentRadius;
  late bool _sentDark;
  late bool _sentHidden;

  late final Map<String, Object> _creationParams = <String, Object>{
    'cornerRadius': _sentRadius = widget.cornerRadius,
    'dark': _sentDark = _dark,
    'hidden': _sentHidden = _hidden,
  };

  bool get _dark => ThemeData.estimateBrightnessForColor(widget.color) == Brightness.dark;

  bool get _hidden => glassSolidity(_model, widget.style) >= 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SheetModel? model = SheetModelOwner.of(context);
    if (identical(model, _model)) return;
    _model?.removeListener(_sync);
    _model = model?..addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(NativeGlassSheetSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _model?.removeListener(_sync);
    super.dispose();
  }

  void _onCreated(int id) {
    _channel = MethodChannel('${_viewType}_$id');
    _sync();
  }

  /// Tells iOS whatever changed since it was last told.
  void _sync() {
    final MethodChannel? channel = _channel;
    if (channel == null) return;
    final double radius = widget.cornerRadius;
    final bool dark = _dark;
    final bool hidden = _hidden;
    if (radius == _sentRadius && dark == _sentDark && hidden == _sentHidden) return;
    _sentRadius = radius;
    _sentDark = dark;
    _sentHidden = hidden;
    // A closing sheet can lose its view before the message lands; the look no longer matters then.
    channel.invokeMethod<void>('update', <String, Object>{
      'cornerRadius': radius,
      'dark': dark,
      'hidden': hidden,
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: UiKitView(
                viewType: _viewType,
                creationParams: _creationParams,
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onCreated,
              ),
            ),
          ),
        ),
        _SolidVeil(style: widget.style, color: widget.color, cornerRadius: widget.cornerRadius, child: widget.child),
      ],
    );
  }
}

/// The sheet's colour over the glass, as opaque as the sheet is solid; repainted only when that changes.
class _SolidVeil extends SingleChildRenderObjectWidget {
  const _SolidVeil({required this.style, required this.color, required this.cornerRadius, required super.child});

  final GlassSheetStyle style;
  final Color color;
  final double cornerRadius;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSolidVeil(model: SheetModelOwner.of(context), style: style, color: color, cornerRadius: cornerRadius);

  @override
  void updateRenderObject(BuildContext context, RenderSolidVeil renderObject) {
    renderObject
      ..model = SheetModelOwner.of(context)
      ..style = style
      ..color = color
      ..cornerRadius = cornerRadius;
  }
}

/// The render object behind the veil over the native glass.
@internal
class RenderSolidVeil extends RenderProxyBox {
  /// Creates the veil's render object.
  RenderSolidVeil({
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

  double _paintedSolidity = -1;

  /// How opaque the veil is now; see [glassSolidity].
  @visibleForTesting
  double get solidity => glassSolidity(_model, _style);

  void _onSheetMoved() {
    if (solidity != _paintedSolidity) markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double solid = _paintedSolidity = solidity;
    if (solid > 0) {
      context.canvas.drawRSuperellipse(
        RSuperellipse.fromRectAndCorners(
          offset & size,
          topLeft: Radius.circular(_cornerRadius),
          topRight: Radius.circular(_cornerRadius),
        ),
        Paint()..color = _color.withValues(alpha: _color.a * solid),
      );
    }
    super.paint(context, offset);
  }

  @override
  void dispose() {
    _model?.removeListener(_onSheetMoved);
    super.dispose();
  }
}
