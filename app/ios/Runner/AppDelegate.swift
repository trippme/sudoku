import Flutter
import Foundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // TEMPORARY diagnostic (issue #60): the APNs device token never reaches the
  // app, so iOS registration is failing. Report the exact failure reason (and a
  // success, if it ever happens) to the backend push_debug endpoint. The success
  // path still calls super so Firebase's swizzling gets the token unaffected.
  // Remove once resolved.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    reportPushDebug("didFailToRegister: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    reportPushDebug("didRegister: apns token len=\(deviceToken.count)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  private func reportPushDebug(_ info: String) {
    guard let url = URL(string: "https://the949dude.com/sudoku/index.php?r=push_debug") else { return }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(
      withJSONObject: ["email": "", "platform": "iOS-native", "info": info])
    URLSession.shared.dataTask(with: req).resume()
  }
}
