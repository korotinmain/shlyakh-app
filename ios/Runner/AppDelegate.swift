import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // SPIKE: observers must be registered before launch finishes so that
    // background relaunches by HealthKit are delivered.
    HealthSpike.shared.startObserving()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // SPIKE: expose the native HealthKit probe to Dart.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HealthSpike") {
      HealthSpikeHostApiSetup.setUp(
        binaryMessenger: registrar.messenger(), api: HealthSpike.shared)
    }
  }
}
