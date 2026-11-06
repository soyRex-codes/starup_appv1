import 'package:flutter/material.dart';
import 'package:foundervers/app/app_initializer.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/services/screenshot_permission_service.dart';

// Global navigator key for push notification deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FAST: Enable screenshots (~10ms)
  await ScreenshotPermissionService.enableScreenshots();

  // START APP IMMEDIATELY - everything else is deferred!
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Terai',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}
