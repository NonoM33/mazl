import Flutter
import UIKit
import UserNotifications

/// Apple Push Notification service for MAZL, on the `mazl/push` method channel
/// (read by `lib/core/services/push_gateway.dart`).
///
/// Dart -> native: `authorizationStatus` (`notDetermined`, `denied`,
/// `authorized`, `provisional`, `ephemeral`), `requestAuthorization` (bool; when
/// granted, registers for remote notifications), `registerForRemoteNotifications`
/// (only when allowed), `setQuiet(bool)` (the Shabbat display: no banner, no
/// sound while the app is open) and `takeLaunchTap` (the notification data that
/// launched the app, or null, then forgotten).
///
/// Native -> Dart: `onToken(hex)` (lowercase hexadecimal), `onTokenError(message)`
/// and `onTap(data)`.
///
/// The server sends the data keys at the root of the payload, next to `aps`;
/// a tap is reported as that dictionary without `aps`.
///
/// One shared object, created in `AppDelegate` before the app finishes launching
/// and set as the notification center's delegate: a tap that starts the app
/// reaches it before Dart listens, so it is kept until `takeLaunchTap`.
final class ApnsPushCenter: NSObject, UNUserNotificationCenterDelegate {
  static let shared = ApnsPushCenter()

  private var channel: FlutterMethodChannel?
  private var quiet = false
  private var dartListening = false
  private var pendingTap: [String: Any]?

  /// Makes this object the notification center's delegate.
  func install() {
    UNUserNotificationCenter.current().delegate = self
  }

  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mazl/push", binaryMessenger: registrar.messenger())
    self.channel = channel
    dartListening = false
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  // MARK: Dart -> native

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "authorizationStatus":
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let name = Self.name(of: settings.authorizationStatus)
        DispatchQueue.main.async { result(name) }
      }
    case "requestAuthorization":
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(code: "authorization", message: error.localizedDescription, details: nil))
            return
          }
          if granted { UIApplication.shared.registerForRemoteNotifications() }
          result(granted)
        }
      }
    case "registerForRemoteNotifications":
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let allowed = Self.isAllowed(settings.authorizationStatus)
        DispatchQueue.main.async {
          if allowed { UIApplication.shared.registerForRemoteNotifications() }
          result(nil)
        }
      }
    case "setQuiet":
      quiet = (call.arguments as? Bool) ?? false
      result(nil)
    case "takeLaunchTap":
      dartListening = true
      let tap = pendingTap
      pendingTap = nil
      result(tap)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func isAllowed(_ status: UNAuthorizationStatus) -> Bool {
    switch status {
    case .authorized, .provisional, .ephemeral: return true
    default: return false
    }
  }

  private static func name(of status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    @unknown default: return "denied"
    }
  }

  // MARK: Token (forwarded by AppDelegate)

  func didRegister(deviceToken: Data) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    channel?.invokeMethod("onToken", arguments: hex)
  }

  func didFailToRegister(error: Error) {
    channel?.invokeMethod("onTokenError", arguments: error.localizedDescription)
  }

  // MARK: UNUserNotificationCenterDelegate

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler(quiet ? [] : [.banner, .list, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let data = Self.data(from: response.notification.request.content.userInfo)
    if dartListening, let channel = channel {
      channel.invokeMethod("onTap", arguments: data)
    } else {
      pendingTap = data
    }
    completionHandler()
  }

  /// The payload's keys as strings, without `aps`.
  private static func data(from userInfo: [AnyHashable: Any]) -> [String: Any] {
    var data: [String: Any] = [:]
    for (key, value) in userInfo {
      guard let key = key as? String, key != "aps" else { continue }
      data[key] = value
    }
    return data
  }
}
