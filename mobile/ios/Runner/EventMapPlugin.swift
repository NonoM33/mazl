import Flutter
import MapKit
import UIKit

/// The map of an event, a native Apple Plans view (MapKit) for the platform
/// view type `mazl/event_map` (used by `lib/presentation/features/events/
/// widgets/event_place_map.dart`). No API key: MapKit is part of iOS.
///
/// Creation parameters: `latitude`, `longitude`, `radius` (metres of the
/// circle that shows the neighbourhood), `pin` (a precise pin, only when the
/// address is public), `dark`, `tint` (ARGB of the circle), `cornerRadius`.
/// Each view answers on the `mazl/event_map_<id>` method channel:
/// `setInteractive` (`{value: Bool}`, false while the page scrolls) and
/// `setDark` (`{value: Bool}`).
///
/// Lives in its own file, listed in the Xcode project.
final class EventMapPlugin: NSObject {
  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      EventMapFactory(messenger: registrar.messenger()),
      withId: "mazl/event_map"
    )
  }
}

final class EventMapFactory: NSObject, FlutterPlatformViewFactory {
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
    EventMapView(
      frame: frame,
      viewId: viewId,
      arguments: args as? [String: Any] ?? [:],
      messenger: messenger
    )
  }
}

final class EventMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
  private let mapView: MKMapView
  private let channel: FlutterMethodChannel
  private let tint: UIColor

  init(
    frame: CGRect,
    viewId: Int64,
    arguments: [String: Any],
    messenger: FlutterBinaryMessenger
  ) {
    mapView = MKMapView(frame: frame)
    channel = FlutterMethodChannel(
      name: "mazl/event_map_\(viewId)",
      binaryMessenger: messenger
    )
    let argb = (arguments["tint"] as? NSNumber)?.uint32Value ?? 0xFF3D5AFE
    tint = UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: 1
    )
    super.init()

    let latitude = (arguments["latitude"] as? NSNumber)?.doubleValue ?? 0
    let longitude = (arguments["longitude"] as? NSNumber)?.doubleValue ?? 0
    let radius = (arguments["radius"] as? NSNumber)?.doubleValue ?? 600
    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

    mapView.delegate = self
    mapView.layer.cornerRadius = CGFloat((arguments["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)
    mapView.layer.masksToBounds = true
    mapView.showsCompass = false
    mapView.showsUserLocation = false
    mapView.isRotateEnabled = false
    mapView.isPitchEnabled = false
    mapView.overrideUserInterfaceStyle =
      (arguments["dark"] as? Bool ?? false) ? .dark : .light
    if #available(iOS 16.0, *) {
      mapView.preferredConfiguration = MKStandardMapConfiguration(
        elevationStyle: .flat,
        emphasisStyle: .muted
      )
    }
    mapView.setRegion(
      MKCoordinateRegion(
        center: center,
        latitudinalMeters: radius * 4.4,
        longitudinalMeters: radius * 4.4
      ),
      animated: false
    )
    mapView.addOverlay(MKCircle(center: center, radius: radius))
    if arguments["pin"] as? Bool ?? false {
      let pin = MKPointAnnotation()
      pin.coordinate = center
      mapView.addAnnotation(pin)
    }
    setInteractive(false)

    channel.setMethodCallHandler { [weak self] call, result in
      let value = (call.arguments as? [String: Any])?["value"] as? Bool ?? false
      switch call.method {
      case "setInteractive":
        self?.setInteractive(value)
        result(nil)
      case "setDark":
        self?.mapView.overrideUserInterfaceStyle = value ? .dark : .light
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { mapView }

  private func setInteractive(_ interactive: Bool) {
    mapView.isUserInteractionEnabled = interactive
    mapView.isScrollEnabled = interactive
    mapView.isZoomEnabled = interactive
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let circle = overlay as? MKCircle else { return MKOverlayRenderer(overlay: overlay) }
    let renderer = MKCircleRenderer(circle: circle)
    renderer.fillColor = tint.withAlphaComponent(0.18)
    renderer.strokeColor = tint.withAlphaComponent(0.85)
    renderer.lineWidth = 2
    return renderer
  }
}
