import Flutter
import UIKit

/// Registers the native side of ona_bottom_sheet: Apple's Liquid Glass behind a sheet.
public final class OnaBottomSheetPlugin: NSObject, FlutterPlugin {
  /// The platform view type the Dart side creates; keep in step with `native_glass_surface.dart`.
  static let glassSurfaceViewType = "ona_bottom_sheet/glass_surface"

  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      OnaGlassSurfaceFactory(messenger: registrar.messenger()),
      withId: glassSurfaceViewType
    )
  }
}
