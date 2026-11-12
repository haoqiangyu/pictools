import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/image_compare_provider.dart';
import 'providers/batch_converter_provider.dart';
import 'layout/foldable_environment.dart';
import 'providers/image_adjust_provider.dart';
import 'providers/image_enhance_provider.dart';
import 'providers/background_removal_provider.dart';
import 'services/settings_provider.dart';
import 'services/window_service.dart';
import 'services/window_arguments.dart';
import 'services/platform_capabilities.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/image_compare_screen.dart';
import 'screens/image_adjust_screen.dart';
import 'screens/image_enhance_screen.dart';
import 'screens/background_removal_screen.dart';
import 'screens/image_converter_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'l10n/app_localizations.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (PlatformCapabilities.supportsRustProcessing) {
    await RustLib.init();
  }

  // 初始化设置
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // 初始化窗口服务并获取当前窗口参数
  final windowArgs = await WindowService.instance.init();

  // 如果是主窗口，初始化 window_manager 并设置窗口属性
  if (PlatformCapabilities.isDesktop && windowArgs.type == WindowType.main) {
    await windowManager.ensureInitialized();

    // Initial desktop window; the content remains responsive.
    const Size initialSize = Size(1400, 900);

    // Match the initial Studio surface while Flutter starts.
    const Color bgColor = Color(0xFFF7F6F2);

    WindowOptions windowOptions = const WindowOptions(
      size: initialSize,
      center: true,
      backgroundColor: bgColor,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
        ChangeNotifierProvider(create: (_) => BatchConverterProvider()),
        ChangeNotifierProvider(create: (_) => ImageCompareProvider()),
        ChangeNotifierProvider(create: (_) => ImageAdjustProvider()),
        ChangeNotifierProvider(create: (_) => ImageEnhanceProvider()),
        ChangeNotifierProvider(create: (_) => BackgroundRemovalProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          builder: (context, child) => FoldableEnvironment(child: child!),
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeListResolutionCallback: AppLocalizations.resolveLocale,
          home: _buildHomeForWindowType(windowArgs.type),
          routes: {
            '/image-compare': (context) => const ImageCompareScreen(),
            '/image-adjust': (context) => const ImageAdjustScreen(),
            '/image-enhance': (context) => const ImageEnhanceScreen(),
            '/background-removal': (context) => Theme(
              data: AppTheme.darkTheme,
              child: const BackgroundRemovalScreen(),
            ),
            '/image-converter': (context) => const ImageConverterScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          },
        ),
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
      case WindowType.backgroundRemoval:
        return Theme(
          data: AppTheme.darkTheme,
          child: const BackgroundRemovalScreen(isStandaloneWindow: true),
        );
      case WindowType.settings:
        return const SettingsScreen(isStandaloneWindow: true);
    }
  }
}
