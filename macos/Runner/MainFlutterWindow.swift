import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 统一窗口尺寸 - 所有窗口使用相同大小
    let initialWidth: CGFloat = 1400
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
    self.minSize = NSSize(width: 1024, height: 700)
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 注册子窗口插件回调 - 让子窗口也能使用 file_picker 等插件
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
    }

    super.awakeFromNib()
  }
}
