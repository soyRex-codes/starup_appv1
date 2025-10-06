import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:foundervers/app/auth_gate.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/services/screenshot_permission_service.dart';
import 'package:foundervers/services/network_service.dart';
import 'package:flutter/foundation.dart';

Future<void> _bootstrap() async {
  // Load env from bundled .env.mobile (client-safe values only)
  try {
    await dotenv.dotenv.load(fileName: '.env.mobile');
  } catch (e) {
    // ignore in production; env file may not exist
  }

  final supabaseUrl = dotenv.dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');
      
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    // Use the new network service with retry logic for Samsung Galaxy devices
    final success = await NetworkService.initializeSupabaseWithRetry(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    if (!success) {
      print('⚠️ Warning: Supabase initialization failed. App may not function properly.');
    } else {
      print('✅ Supabase initialized successfully');
    }
  } else {
    print('❌ Error: Missing Supabase URL or Anon Key');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();

  // Enable screenshots for social media sharing
  await ScreenshotPermissionService.enableScreenshots();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FounderVers',
      theme: buildAppTheme(),
      home: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const AuthGate(),
              ),
            )
          : const AuthGate(),
    );
  }
}
