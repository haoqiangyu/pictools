import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_compare_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PictoolsApp());
}

class PictoolsApp extends StatelessWidget {
  const PictoolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageCompareProvider(),
      child: MaterialApp(
        title: 'Pictools',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
