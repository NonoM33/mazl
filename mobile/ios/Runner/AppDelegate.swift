import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Before `super`: a tap on a notification that launches the app is
    // delivered to the delegate right away, before Dart listens.
    ApnsPushCenter.shared.install()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    ApnsPushCenter.shared.didRegister(deviceToken: deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ApnsPushCenter.shared.didFailToRegister(error: error)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FoldPosturePlugin") {
      FoldPosturePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EventMapPlugin") {
      EventMapPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconPlugin") {
      AppIconPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ApnsPushPlugin") {
      ApnsPushCenter.shared.register(with: registrar)
    }
    // A plugin may have taken the delegate during registration: the tap that
    // launched the app must reach ApnsPushCenter.
    ApnsPushCenter.shared.install()
  }
}

/// The icon of the app on the home screen, on the `mazl/app_icon` method
/// channel (read by `lib/core/storefront/app_icon_gateway.dart`):
/// `supportsAlternateIcons`, `alternateIconName` and `setAlternateIconName`
/// (`{name: String?}`, null brings the normal icon back).
///
/// Lives in this file because the Xcode project lists its sources one by one.
final class AppIconPlugin: NSObject {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mazl/app_icon", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "supportsAlternateIcons":
        result(UIApplication.shared.supportsAlternateIcons)
      case "alternateIconName":
        result(UIApplication.shared.alternateIconName)
      case "setAlternateIconName":
        let arguments = call.arguments as? [String: Any]
        let name = arguments?["name"] as? String
        UIApplication.shared.setAlternateIconName(name) { error in
          if let error = error {
            result(FlutterError(code: "icon_change_failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
