import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_compare_provider.dart';
import 'providers/image_adjust_provider.dart';
import 'providers/image_enhance_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/image_compare_screen.dart';
import 'screens/image_adjust_screen.dart';
import 'screens/image_enhance_screen.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const PictoolsApp());
}

class PictoolsApp extends StatelessWidget {
  const PictoolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageCompareProvider()),
        ChangeNotifierProvider(create: (_) => ImageAdjustProvider()),
        ChangeNotifierProvider(create: (_) => ImageEnhanceProvider()),
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
        },
      ),
    );
  }
}
