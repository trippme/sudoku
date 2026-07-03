import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // iOS only mints an APNs device token after registerForRemoteNotifications()
    // is called. When notification permission is already granted, the
    // firebase_messaging plugin's requestPermission() returns without
    // re-triggering registration, so the APNs token (and thus the FCM token)
    // never arrives and the device can't be registered for push. Register
    // explicitly on every launch; Firebase's method swizzling forwards the
    // resulting token to the SDK. (issue #60)
    application.registerForRemoteNotifications()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
