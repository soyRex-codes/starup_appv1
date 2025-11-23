import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:foundervers/app/auth_gate.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/services/screenshot_permission_service.dart';
import 'package:foundervers/services/network_service.dart';
import 'package:foundervers/services/iap_service.dart';
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
  final stripePublishableKey =
      dotenv.dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ??
          const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  // Initialize Stripe (mobile only - not supported on web)
  // Stripe is used for business services (tax help, legal, etc.) on both iOS and Android
  // This is compliant with Apple guidelines 3.1.3(b) for real-world services
  if (!kIsWeb && stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = stripePublishableKey;

      // Configure Stripe
      await Stripe.instance.applySettings();

      log('✅ Stripe initialized successfully');
      log('🔑 Using publishable key: ${stripePublishableKey.substring(0, 15)}...');
    } catch (e) {
      log('⚠️ Warning: Stripe initialization failed: $e');
      log('Stack trace: ${StackTrace.current}');
    }
  } else if (kIsWeb) {
    log('ℹ️ Stripe skipped on web platform');
  } else {
    log('⚠️ Warning: Stripe publishable key not found');
  }

  // Initialize Apple In-App Purchase on iOS for premium subscriptions only
  if (!kIsWeb && Platform.isIOS) {
    try {
      final iapService = IAPService();
      final isAvailable = await iapService.initialize();

      if (isAvailable) {
        log('✅ Apple In-App Purchase initialized successfully');
      } else {
        log('⚠️ Apple In-App Purchase not available');
      }
    } catch (e) {
      log('⚠️ Warning: IAP initialization failed: $e');
    }
  }

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    // Use the new network service with retry logic for Samsung Galaxy devices
    final success = await NetworkService.initializeSupabaseWithRetry(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    if (!success) {
      log('⚠️ Warning: Supabase initialization failed. App may not function properly.');
    } else {
      log('✅ Supabase initialized successfully');
    }
  } else {
    log('❌ Error: Missing Supabase URL or Anon Key');
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
      title: 'Foundervers',
      debugShowCheckedModeBanner: false, // Remove DEBUG banner for App Store
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system, // Auto-follow device theme
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
