import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_compare_provider.dart';
import 'providers/image_adjust_provider.dart';
import 'providers/image_enhance_provider.dart';
import 'providers/ai_image_provider.dart';
import 'services/settings_provider.dart';
import 'services/window_service.dart';
import 'services/window_arguments.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/image_compare_screen.dart';
import 'screens/image_adjust_screen.dart';
import 'screens/image_enhance_screen.dart';
import 'screens/ai_image_screen.dart';
import 'screens/settings_screen.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // 初始化窗口服务
  await WindowService.instance.init();

  // 初始化设置
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // 获取当前窗口参数
  final windowArgs =
      WindowService.instance.currentArguments ??
      const WindowArguments(type: WindowType.main);

  runApp(
    PictoolsApp(settingsProvider: settingsProvider, windowArgs: windowArgs),
  );
}

class PictoolsApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final WindowArguments windowArgs;

  const PictoolsApp({
    super.key,
    required this.settingsProvider,
    required this.windowArgs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ImageCompareProvider()),
        ChangeNotifierProvider(create: (_) => ImageAdjustProvider()),
        ChangeNotifierProvider(create: (_) => ImageEnhanceProvider()),
        ChangeNotifierProvider(create: (_) => AIImageProvider()),
      ],
      child: MaterialApp(
        title: windowArgs.windowTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: _buildHomeForWindowType(windowArgs.type),
        routes: {
          '/image-compare': (context) => const ImageCompareScreen(),
          '/image-adjust': (context) => const ImageAdjustScreen(),
          '/image-enhance': (context) => const ImageEnhanceScreen(),
          '/ai-image': (context) => const AIImageScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }

  /// 根据窗口类型构建初始页面
  Widget _buildHomeForWindowType(WindowType type) {
    switch (type) {
      case WindowType.main:
        return const HomeScreen();
      case WindowType.imageCompare:
        return const ImageCompareScreen(isStandaloneWindow: true);
      case WindowType.imageAdjust:
        return const ImageAdjustScreen(isStandaloneWindow: true);
      case WindowType.imageEnhance:
        return const ImageEnhanceScreen(isStandaloneWindow: true);
      case WindowType.aiImage:
        return const AIImageScreen(isStandaloneWindow: true);
      case WindowType.settings:
        return const SettingsScreen(isStandaloneWindow: true);
    }
  }
}
