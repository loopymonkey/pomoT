import Cocoa
import AVFoundation
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  private var audioPlayer: AVAudioPlayer?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    let soundChannel = FlutterMethodChannel(
      name: "pomot/sound",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    soundChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "play", let assetPath = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }

      // Flutter assets live inside App.framework on macOS, not Bundle.main
      let appFrameworkURL = Bundle.main.bundleURL
        .appendingPathComponent("Contents/Frameworks/App.framework")
      guard let appBundle = Bundle(url: appFrameworkURL),
            let resourceURL = appBundle.resourceURL else {
        result(FlutterError(code: "BUNDLE_ERROR", message: "Cannot locate App.framework", details: nil))
        return
      }

      let url = resourceURL
        .appendingPathComponent("flutter_assets")
        .appendingPathComponent(assetPath)

      do {
        self?.audioPlayer = try AVAudioPlayer(contentsOf: url)
        self?.audioPlayer?.prepareToPlay()
        self?.audioPlayer?.play()
        result(nil)
      } catch {
        result(FlutterError(
          code: "PLAY_ERROR",
          message: error.localizedDescription,
          details: url.path
        ))
      }
    }

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
