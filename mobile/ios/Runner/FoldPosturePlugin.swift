import Flutter
import UIKit

/// Streams the fold of a foldable iPhone to Dart on the `mazl/fold` event
/// channel (read by `lib/core/layout/fold_channel.dart`).
///
/// Each message is `{hinge, divisions}`: the hinge status of
/// `UIHingeInteraction` and the ACTIVE division regions of the Flutter view
/// (`reservedRegions(kind: .division)`), in points of that view, which are
/// Flutter's logical pixels. Before iOS 27.1, or on a device without a hinge,
/// a single `unknown` message with no division is sent.
final class FoldPosturePlugin: NSObject, FlutterStreamHandler {
  private weak var registrar: FlutterPluginRegistrar?
  private var observer: UIView?
  private var sink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = FoldPosturePlugin()
    plugin.registrar = registrar
    let channel = FlutterEventChannel(name: "mazl/fold", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(plugin)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    guard #available(iOS 27.1, *), let view = flutterView else {
      events(["hinge": "unknown", "divisions": []])
      return nil
    }
    let observer = FoldObserverView(frame: view.bounds) { [weak self] message in
      self?.sink?(message)
    }
    view.addSubview(observer)
    observer.setNeedsLayout()
    self.observer = observer
    return nil
  }

  /// The view Flutter draws in: the registrar's, else the root view of the
  /// app's window (the implicit engine may not hand its view controller to
  /// the registrar).
  private var flutterView: UIView? {
    if let view = registrar?.viewController?.view { return view }
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
    return window?.rootViewController?.view
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observer?.removeFromSuperview()
    observer = nil
    sink = nil
    return nil
  }
}

/// An invisible view laid over the Flutter view: it follows its size, holds
/// the hinge interaction and reads the reserved regions after every layout
/// (folding resizes and re-lays out the window).
@available(iOS 27.1, *)
private final class FoldObserverView: UIView {
  private let send: ([String: Any]) -> Void
  private var hinge: UIHinge.Status = .unknown
  private var lastMessage: NSDictionary?

  init(frame: CGRect, send: @escaping ([String: Any]) -> Void) {
    self.send = send
    super.init(frame: frame)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addInteraction(UIHingeInteraction { [weak self] _, update in
      self?.hinge = update.hinge?.status ?? .unknown
      self?.report()
    })
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    report()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    report()
  }

  private func report() {
    let divisions = reservedRegions(kind: .division)
      .filter(\.isActive)
      .map { region in
        [
          "x": Double(region.frame.origin.x),
          "y": Double(region.frame.origin.y),
          "width": Double(region.frame.size.width),
          "height": Double(region.frame.size.height),
        ]
      }
    let message: [String: Any] = ["hinge": Self.name(of: hinge), "divisions": divisions]
    let dictionary = message as NSDictionary
    guard dictionary != lastMessage else { return }
    lastMessage = dictionary
    send(message)
  }

  private static func name(of status: UIHinge.Status) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partiallyOpen"
    case .fullyOpen: return "fullyOpen"
    default: return "unknown"
    }
  }
}
