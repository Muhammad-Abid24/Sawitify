import AVKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioOutputChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioOutputChannel(binaryMessenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerAudioOutputChannel(binaryMessenger: FlutterBinaryMessenger) {
    audioOutputChannel = FlutterMethodChannel(
      name: "audio_output",
      binaryMessenger: binaryMessenger
    )

    audioOutputChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "showIOSRoutePicker", "show":
        self?.showIOSRoutePicker()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func showIOSRoutePicker() {
    DispatchQueue.main.async {
      guard let rootView = self.currentRootViewController()?.view else {
        return
      }

      let routePickerView = AVRoutePickerView(frame: CGRect(x: -100, y: -100, width: 1, height: 1))
      routePickerView.alpha = 0.01
      routePickerView.activeTintColor = .clear
      routePickerView.tintColor = .clear
      rootView.addSubview(routePickerView)

      if let routeButton = routePickerView.subviews.compactMap({ $0 as? UIButton }).first {
        routeButton.sendActions(for: .touchUpInside)
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        routePickerView.removeFromSuperview()
      }
    }
  }

  private func currentRootViewController() -> UIViewController? {
    if let rootViewController = window?.rootViewController {
      return rootViewController
    }

    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
  }
}
