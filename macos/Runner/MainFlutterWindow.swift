import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Don't let macOS restore a previously resized/positioned frame across
    // launches — always start at the same comfortable desktop size so the
    // sidebar's large-screen (push, not overlay) layout is used by default.
    self.isRestorable = false

    let flutterViewController = FlutterViewController()
    let defaultSize = NSSize(width: 1280, height: 800)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let origin = NSPoint(
      x: screenFrame.origin.x + (screenFrame.width - defaultSize.width) / 2,
      y: screenFrame.origin.y + (screenFrame.height - defaultSize.height) / 2
    )
    let windowFrame = NSRect(origin: origin, size: defaultSize)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
