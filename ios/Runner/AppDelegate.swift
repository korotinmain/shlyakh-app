import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Before launch finishes, so HealthKit's background relaunches reach it.
    StepsObserver.shared.start()
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StepsHost") {
      StepsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: StepsHost.shared)
      StepsObserver.shared.attach(events: StepsEventsApi(binaryMessenger: registrar.messenger()))
    }
  }
}
