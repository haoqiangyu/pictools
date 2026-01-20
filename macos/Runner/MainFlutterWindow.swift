import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 设置最小窗口尺寸
    self.minSize = NSSize(width: 1024, height: 700)
    
    // 窗口样式设置 - 尺寸由 Dart 侧 window_manager 统一管理
    // 使用深色背景避免白色闪烁，并设置透明标题栏
    self.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // 匹配 AppTheme.primaryBg
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 注册子窗口插件回调 - 让子窗口也能使用 file_picker 等插件
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
    }

    super.awakeFromNib()
  }
}
