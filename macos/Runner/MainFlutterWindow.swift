import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 设置更大的初始窗口尺寸
    let initialWidth: CGFloat = 1280
    let initialHeight: CGFloat = 900
    
    // 获取屏幕尺寸用于居中显示
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      let originX = (screenRect.width - initialWidth) / 2 + screenRect.origin.x
      let originY = (screenRect.height - initialHeight) / 2 + screenRect.origin.y
      let windowFrame = NSRect(x: originX, y: originY, width: initialWidth, height: initialHeight)
      self.setFrame(windowFrame, display: true)
    }
    
    // 设置最小窗口尺寸
    self.minSize = NSSize(width: 1024, height: 768)
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
