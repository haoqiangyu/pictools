import Flutter
import UIKit
import Photos

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PictoolsPhotoLibrary") {
      PictoolsPhotoLibrary.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PictoolsWindowGeometry") {
      PictoolsWindowGeometry.register(with: registrar)
    }
  }
}

/// Reports this engine's view geometry, never UIScreen.main. iOS 27.1 builds
/// additionally expose active division/occlusion regions to Flutter.
final class PictoolsWindowGeometry: NSObject, FlutterPlugin, FlutterStreamHandler {
  private weak var registrar: FlutterPluginRegistrar?
  private var observer: GeometryObserver?
  private var sink: FlutterEventSink?
  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = PictoolsWindowGeometry()
    plugin.registrar = registrar
    FlutterEventChannel(name: "pictools/window_geometry", binaryMessenger: registrar.messenger()).setStreamHandler(plugin)
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.sink != nil, let view = self.registrar?.viewController?.view else { return }
      self.observer?.stop(); self.observer?.removeFromSuperview()
      let observer = GeometryObserver(frame: view.bounds)
      observer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      observer.isUserInteractionEnabled = false
      observer.backgroundColor = .clear
      observer.emit = events
      view.insertSubview(observer, at: 0)
      self.observer = observer
      observer.start()
    }
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observer?.stop(); observer?.removeFromSuperview(); observer = nil; sink = nil
    return nil
  }
}
private final class GeometryObserver: UIView {
  var emit: FlutterEventSink?
  private var link: CADisplayLink?
  private var previous: NSDictionary?
  func start() {
    let link = CADisplayLink(target: self, selector: #selector(publish))
    link.preferredFramesPerSecond = 10
    link.add(to: .main, forMode: .common)
    self.link = link
    publish()
  }
  func stop() { link?.invalidate(); link = nil }
  override func layoutSubviews() { super.layoutSubviews(); publish() }
  @objc private func publish() {
    guard let view = superview, let scene = view.window?.windowScene,
          scene.activationState == .foregroundActive else { return }
    let insets = view.safeAreaInsets
    var divisions = [[Double]](), occlusions = [[Double]]()
    var supported = false
    #if PICTOOLS_DUO_SDK
    if #available(iOS 27.1, *) {
      func coordinates(_ frame: CGRect) -> [Double] {
        [Double(frame.minX), Double(frame.minY), Double(frame.width), Double(frame.height)]
      }
      divisions = view.reservedRegions(kind: .division).map { coordinates($0.frame) }
      occlusions = view.reservedRegions(kind: .occlusion).map { coordinates($0.frame) }
      supported = true
    }
    #endif
    let value: NSDictionary = [
      "size": [Double(view.bounds.width), Double(view.bounds.height)],
      "safeInsets": [Double(insets.left), Double(insets.top), Double(insets.right), Double(insets.bottom)],
      "regularWidth": view.traitCollection.horizontalSizeClass == .regular,
      "regionsSupported": supported,
      "divisions": divisions, "occlusions": occlusions
    ]
    if previous != value { previous = value; emit?(value) }
  }
}

/// Write-only Photos export. Never fetches or modifies existing assets.
final class PictoolsPhotoLibrary: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pictools/photo_library", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PictoolsPhotoLibrary(), channel: channel)
  }
  private func authorize(_ completion: @escaping (FlutterError?) -> Void) {
    let respond: (PHAuthorizationStatus) -> Void = { status in
      DispatchQueue.main.async {
        switch status {
        case .authorized, .limited: completion(nil)
        case .restricted: completion(FlutterError(code: "permission_restricted", message: "Photos is restricted", details: nil))
        default: completion(FlutterError(code: "permission_denied", message: "Permission to add photos denied", details: nil))
        }
      }
    }
    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    if status == .notDetermined { PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: respond) }
    else { respond(status) }
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission": authorize { result($0) }
    case "openSettings":
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return result(nil) }
      UIApplication.shared.open(url) { opened in
        result(opened ? nil : FlutterError(code: "settings_failed", message: "Cannot open Settings", details: nil))
      }
    case "saveImage":
      guard let args = call.arguments as? [String: Any],
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            let name = args["fileName"] as? String,
            let ext = args["extension"] as? String,
            ["png", "jpg"].contains(ext), !bytes.data.isEmpty else {
        return result(FlutterError(code: "invalid_image", message: "PNG or JPEG required", details: nil))
      }
      authorize { error in
        if let error = error { result(error); return }
        PHPhotoLibrary.shared().performChanges({
          let options = PHAssetResourceCreationOptions()
          options.originalFilename = (name as NSString).lastPathComponent
          let request = PHAssetCreationRequest.forAsset()
          request.addResource(with: .photo, data: bytes.data, options: options)
        }) { success, error in
          DispatchQueue.main.async {
            result(success ? nil : FlutterError(code: "save_failed", message: error?.localizedDescription ?? "Photos save failed", details: nil))
          }
        }
      }
    default: result(FlutterMethodNotImplemented)
    }
  }
}
