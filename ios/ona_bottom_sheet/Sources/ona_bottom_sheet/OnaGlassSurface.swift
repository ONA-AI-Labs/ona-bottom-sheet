import Flutter
import UIKit

/// Creates the glass surface behind each glass sheet.
final class OnaGlassSurfaceFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    OnaGlassSurface(frame: frame, viewId: viewId, arguments: args as? [String: Any], messenger: messenger)
  }
}

/// The view behind a glass sheet: Apple's Liquid Glass (`UIGlassEffect`) in the sheet's shape, a rectangle with
/// rounded top corners. It never takes a touch; the sheet's Flutter content above it does.
///
/// Its own channel, `ona_bottom_sheet/glass_surface_<id>`, takes `update` with the glass's whole state, as do the
/// creation arguments: `cornerRadius`, `dark`, `hidden` (the sheet has turned solid, so the glass need not be drawn)
/// and `tint` (an ARGB colour mixed into the glass; absent for none).
final class OnaGlassSurface: NSObject, FlutterPlatformView {
  private let container: UIView
  private let channel: FlutterMethodChannel
  private var glass: UIVisualEffectView?
  /// The tint the glass was made with, as ARGB; nil for none.
  private var tint: UInt32?

  init(frame: CGRect, viewId: Int64, arguments: [String: Any]?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    container.isUserInteractionEnabled = false
    channel = FlutterMethodChannel(
      name: "\(OnaBottomSheetPlugin.glassSurfaceViewType)_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    if #available(iOS 26.0, *) {
      let glass = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
      glass.frame = container.bounds
      glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      glass.isUserInteractionEnabled = false
      container.addSubview(glass)
      self.glass = glass
    }
    apply(arguments)

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.apply(call.arguments as? [String: Any])
      result(nil)
    }
  }

  func view() -> UIView {
    container
  }

  private func apply(_ arguments: [String: Any]?) {
    guard let arguments else { return }
    if let dark = arguments["dark"] as? Bool {
      // The glass follows the sheet's theme, not the phone's, so it always matches the Flutter content on it.
      container.overrideUserInterfaceStyle = dark ? .dark : .light
    }
    if let hidden = arguments["hidden"] as? Bool {
      container.isHidden = hidden
    }
    // A new effect only when the tint changes: every message repeats the whole state.
    let tint = (arguments["tint"] as? NSNumber)?.uint32Value
    if #available(iOS 26.0, *), let glass, tint != self.tint {
      self.tint = tint
      let effect = UIGlassEffect(style: .regular)
      effect.tintColor = tint.map(Self.color)
      glass.effect = effect
    }
    if #available(iOS 26.0, *), let glass, let radius = arguments["cornerRadius"] as? NSNumber {
      let top = UICornerRadius.fixed(radius.doubleValue)
      glass.cornerConfiguration = .corners(
        topLeftRadius: top,
        topRightRadius: top,
        bottomLeftRadius: .fixed(0),
        bottomRightRadius: .fixed(0)
      )
    }
  }

  /// The sRGB colour of a Flutter `Color.toARGB32()`.
  private static func color(_ argb: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat(argb >> 24) / 255
    )
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }
}
