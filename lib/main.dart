import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_compare_provider.dart';
import 'providers/image_adjust_provider.dart';
import 'providers/image_enhance_provider.dart';
import 'providers/ai_image_provider.dart';
import 'services/settings_provider.dart';
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

  // 初始化设置
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(PictoolsApp(settingsProvider: settingsProvider));
}

class PictoolsApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const PictoolsApp({super.key, required this.settingsProvider});

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
        title: 'Pictools',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
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
}
