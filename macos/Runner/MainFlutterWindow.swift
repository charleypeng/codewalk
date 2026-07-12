import Cocoa
import FlutterMacOS
import desktop_multi_window
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      FlutterMultiWindowPlugin.register(
        with: controller.registrar(forPlugin: "FlutterMultiWindowPlugin")
      )
      WindowManagerPlugin.register(
        with: controller.registrar(forPlugin: "WindowManagerPlugin")
      )
    }

    super.awakeFromNib()
  }
}
