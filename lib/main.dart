import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:foundervers/app/app_initializer.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/services/screenshot_permission_service.dart';
import 'package:flutter/foundation.dart';

// Global navigator key for push notification deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FAST: Only load env file (contains URLs, ~50ms)
  try {
    await dotenv.dotenv.load(fileName: '.env.mobile');
  } catch (e) {
    // Silently continue - will fallback to String.fromEnvironment
  }

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
      title: 'Foundervers',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const AppInitializer(),
              ),
            )
          : const AppInitializer(),
    );
  }
}
